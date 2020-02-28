module SpreeShipworks
  class UpdateStatus
    include Dsl

    def call(params)
      # TODO process comments params
      if Setting[:use_split_shipments] && splitted_order?(params)
        shipment_number = params['order'].split('-').last
        if shipment = ::Spree::Shipment.find_by_number(shipment_number)
          shipment.send("#{params['status']}!".to_sym)

          response do |r|
            r.element 'UpdateSuccess'
          end
        end
      else
        order_number = params['order'].split('-').first
        if order = ::Spree::Order.find_by_number(order_number)
          order.shipments.each do |shipment|
            shipment.send("#{params['status']}!".to_sym)
          end

          response do |r|
            r.element 'UpdateSuccess'
          end
        end
      end

    rescue ActiveRecord::RecordNotFound
      error_response("NOT_FOUND", "Unable to find an order with ID of '#{params['order']}'.")
    rescue StateMachines::InvalidTransition, NoMethodError => error
      error_response("INVALID_STATUS", error.to_s)
    rescue => error
      error_response("INTERNAL_SERVER_ERROR", error.to_s)
    end

    private

    def splitted_order?(params)
      params['order'].split('-').last.start_with?('H')
    end
  end
end
