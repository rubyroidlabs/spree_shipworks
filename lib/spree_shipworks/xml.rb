# frozen_string_literal: true

module SpreeShipworks
  module Xml
    module Address
      def to_shipworks_xml(name, context)
        context.element name do |a|
          a.element 'FullName',   full_name
          a.element 'Company',    '' # self.user.try(:company)
          a.element 'Street1',    address1
          a.element 'Street2',    address2
          a.element 'City',       city
          a.element 'State',      state.try(:abbr)
          a.element 'PostalCode', zipcode
          a.element 'Country',    country.try(:iso_name)
          a.element 'Phone',      phone
          a.element 'Fax',        ''
          a.element 'Email',      '' # self.user.try(:email)
        end
      end
    end # Address

    module Note
      def to_shipworks_xml(context, note)
        context.element 'Notes' do |n|
          n.element 'Note', note
        end
      end
    end # Note

    module Adjustment
      def to_shipworks_xml(context)
        if amount.present?
          context.element 'Total', format('%01.2f', amount.abs),
                          id: id,
                          name: label,
                          impact: impact
        end
      end

      def impact
        if amount&.negative?
          'subtract'
        elsif amount&.positive?
          'add'
        else
          'none'
        end
      end
    end # Adjustment

    module Creditcard
      def to_shipworks_xml(context)
        context.element 'CreditCard' do |cc|
          cc.element 'Type', cc_type || 'unknown' if respond_to?(:cc_type)
          begin
            cc.element 'Owner', name || ''
          rescue StandardError
            ''
          end
          begin
            cc.element 'Number', display_number || ''
          rescue StandardError
            ''
          end
          begin
            cc.element 'Expires', expires || ''
          rescue StandardError
            ''
          end
          begin
            cc.element 'CCV', verification_value if verification_value?
          rescue StandardError
            ''
          end
        end
      end

      def expires
        "#{month}/#{year}" if month.present? || year.present?
      end
    end # CreditCard

    module LineItem
      def to_shipworks_xml(context)
        context.element 'Item' do |i|
          i.element 'ItemID',    id if id.present?
          i.element 'ProductID', product.id if product.present?
          i.element 'Code',      variant.sku if variant.present?
          i.element 'SKU',       variant.sku if variant.present?
          i.element 'Name',      variant.name if product.present?
          i.element 'Quantity',  quantity
          i.element 'UnitPrice', format('%01.2f', price)
          if variant.present? && variant.cost_price
            i.element 'UnitCost', format('%01.2f', variant.cost_price)
          end
          i.element 'Weight',    variant.weight || 0.0 if variant.present?

          i.element 'Attributes' do |attributes|
            variant.option_values.each do |option|
              attributes.element 'Attribute' do |attribute|
                attribute.element 'AttributeID',  option.option_type_id
                attribute.element 'Name',         option.option_type.presentation
                attribute.element 'Value',        option.presentation
              end
            end

            if respond_to?(:ad_hoc_option_values)
              ad_hoc_option_values.each do |option|
                attributes.element 'Attribute' do |attribute|
                  attribute.element 'AttributeID',  option.ad_hoc_option_type.option_type_id
                  attribute.element 'Name',         option.ad_hoc_option_type.option_type.presentation
                  attribute.element 'Value',        option.option_value.presentation
                  attribute.element 'Price',        option.price_modifier
                end
              end
            end
          end
        end
      end
    end # LineItem

    module InventoryUnit
      def to_shipworks_xml(context)
        line_item = self.line_item
        variant = self.variant
        product = variant.product

        context.element 'Item' do |i|
          i.element 'ItemID',    id if id.present?
          i.element 'ProductID', product.id if product.present?
          i.element 'Code',      variant.sku if variant.present?
          i.element 'SKU',       variant.sku if variant.present?
          i.element 'Name',      variant.name if product.present?
          i.element 'Quantity',  quantity
          i.element 'UnitPrice', format('%01.2f', line_item.price)
          if variant.present? && variant.cost_price
            i.element 'UnitCost', format('%01.2f', variant.cost_price)
          end
          i.element 'Weight',    variant.weight || 0.0 if variant.present?

          i.element 'Attributes' do |attributes|
            variant.option_values.each do |option|
              attributes.element 'Attribute' do |attribute|
                attribute.element 'AttributeID',  option.option_type_id
                attribute.element 'Name',         option.option_type.presentation
                attribute.element 'Value',        option.presentation
              end
            end

            if respond_to?(:ad_hoc_option_values)
              ad_hoc_option_values.each do |option|
                attributes.element 'Attribute' do |attribute|
                  attribute.element 'AttributeID',  option.ad_hoc_option_type.option_type_id
                  attribute.element 'Name',         option.ad_hoc_option_type.option_type.presentation
                  attribute.element 'Value',        option.option_value.presentation
                  attribute.element 'Price',        option.price_modifier
                end
              end
            end
          end
        end
      end
    end # InventoryUnit

    module Order
      def to_shipworks_xml(context)
        context.element 'Order' do |order_context|
          if try(:editable_order_number)
            order_context.element 'OrderNumber',    editable_order_number
          elsif number =~ /[a-zA-Z]/
            order_context.element 'OrderNumber',    number_without_letters(number)
            order_context.element 'OrderNumberPrefix', number_prefix(number)
          else
            order_context.element 'OrderNumber', number
          end
          # order_context.element 'OrderID',        self.id
          order_context.element 'OrderDate',      completed_at.to_s(:db).gsub(' ', 'T')
          order_context.element 'LastModified',   updated_at.to_s(:db).gsub(' ', 'T')
          order_context.element 'ShippingMethod', shipments.first.try(:shipping_method).try(:name)
          order_context.element 'StatusCode',     state
          order_context.element 'CustomerID',     user_id

          if special_instructions.present?
            special_instructions.extend(Note)
            special_instructions.to_shipworks_xml(order_context, special_instructions)
          end

          if ship_address
            ship_address.extend(Address)
            ship_address.to_shipworks_xml('ShippingAddress', order_context)
          end

          if bill_address
            bill_address.extend(Address)
            bill_address.to_shipworks_xml('BillingAddress', order_context)
          end

          if payments.first.present?
            payment = payments.first.extend(::SpreeShipworks::Xml::Payment)
            payment.to_shipworks_xml(order_context)
          end

          if line_items.present?
            order_context.element 'Items' do |items_context|
              line_items.each do |item|
                next if item.quantity.zero?

                item.extend(LineItem)
                item.to_shipworks_xml(items_context) if item.variant.present?
              end
            end
          end

          order_context.element 'Totals' do |totals_context|
            if line_item_adjustments.nonzero.exists?
              line_item_adjustments.nonzero.promotion.eligible.each do |promotion|
                promotion.extend(Adjustment)
                promotion.to_shipworks_xml(totals_context)
              end
            end

            line_item_adjustments.nonzero.tax.eligible.each do |tax|
              tax.extend(Adjustment)
              tax.to_shipworks_xml(totals_context)
            end

            if shipment_adjustments.nonzero.exists?
              shipment_adjustments.nonzero.promotion.eligible.each do |tax|
                tax.extend(Adjustment)
                tax.to_shipworks_xml(totals_context)
              end
            end

            shipments.where(state: 'ready').each do |shipment|
              shipment.extend(Shipment)
              shipment.extend(Adjustment)
              shipment.to_shipworks_xml(totals_context)
            end

            if adjustments.nonzero.eligible.exists?
              adjustments.nonzero.eligible.each do |adjustment|
                adjustment.extend(Adjustment)
                adjustment.to_shipworks_xml(totals_context)
              end
            end
          end
        end
      end

      def number_without_letters(big_string)
        big_string.gsub(/[A-Za-z]+/, '')
      end

      def number_prefix(big_string)
        big_string.gsub(/[0-9]+/, '')
      end
    end # Order

    module Shipment
      def to_shipworks_xml(context)
        order = self.order
        context.element 'Order' do |order_context|
          order_context.element 'OrderNumber',    "#{order.number}-#{number}"
          order_context.element 'OrderDate',      order.completed_at.to_s(:db).gsub(' ', 'T')
          order_context.element 'LastModified',   updated_at.to_s(:db).gsub(' ', 'T')
          order_context.element 'ShippingMethod', shipping_method.name
          order_context.element 'StatusCode',     state
          order_context.element 'CustomerID',     order.user_id

          if order.special_instructions.present?
            order.special_instructions.extend(Note)
            order.special_instructions.to_shipworks_xml(order_context, order.special_instructions)
          end

          if order.ship_address
            order.ship_address.extend(Address)
            order.ship_address.to_shipworks_xml('ShippingAddress', order_context)
          end

          if order.bill_address
            order.bill_address.extend(Address)
            order.bill_address.to_shipworks_xml('BillingAddress', order_context)
          end

          if order.payments.first.present?
            payment = order.payments.first.extend(::SpreeShipworks::Xml::Payment)
            payment.to_shipworks_xml(order_context)
          end

          if inventory_units.present?
            order_context.element 'Items' do |items_context|
              inventory_units.each do |item|
                next if item.quantity.zero?

                item.extend(InventoryUnit)
                item.to_shipworks_xml(items_context) if item.variant.present?
              end
            end
          end

          order_context.element 'Totals' do |totals_context|
            order.adjustments.each do |adjustment|
              adjustment.extend(Adjustment)
              adjustment.to_shipworks_xml(totals_context)
            end
          end
        end
      end
    end # Shipment

    module Payment
      def to_shipworks_xml(context)
        context.element 'Payment' do |payment_context|
          payment_context.element 'Method', payment_source.class.name.split('::').last
          if source.present? && source.respond_to?(:cc_type)
            source.extend(Creditcard)
            source.to_shipworks_xml(payment_context)
          end
        end
      end
    end # Payment

    module Shipment
      def amount
        cost
      end

      def label
        'shipment cost'
      end
    end # SmallShipment
  end
end
