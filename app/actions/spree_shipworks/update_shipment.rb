module SpreeShipworks
  class UpdateShipment
    include Dsl

    def call(params)
      if Setting[:use_split_shipments] && splitted_order?(params)
        shipment_number = params['order'].split('-').last
        shipment = Spree::Shipment.find_by_number(shipment_number)
      else
        order_number = params['order'].split('-').first
        order = Spree::Order.find_by_number(order_number)
        shipment = order.shipments.first
      end

      if shipment.try(:update_attributes, update_params(params))
        response do |r|
          r.element 'UpdateSuccess'
        end
      else
        Honeybadger.notify(error_response)
        error_response("UNPROCESSIBLE_ENTITY", "Could not update tracking information for Order ##{params['order']}")
      end

    rescue ActiveRecord::RecordNotFound
      error_response("NOT_FOUND", "Unable to find an order with ID of '#{params['order']}'.")
    rescue => error
      error_response("INTERNAL_SERVER_ERROR", error.to_s)
    end

    private

    def update_params(params)
      { :tracking => params['tracking'] }
    end

    def splitted_order?(params)
      params['order'].split('-').last.start_with?('H')
    end
  end
end
