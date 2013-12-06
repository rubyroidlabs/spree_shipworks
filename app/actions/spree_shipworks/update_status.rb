module SpreeShipworks
  class UpdateStatus
    include Dsl

    def call(params)
      if SpreeShipworks::Config.use_split_shipments
        number = "H#{params['order']}"
        if shipment = Spree::Shipment.find_by_number(number) || raise(ActiveRecord::RecordNotFound)
          shipment.send("#{params['status']}!".to_sym)

          response do |r|
            r.element 'UpdateSuccess'
          end
        end
      else
        number = "R#{params['order']}"
        if order = Spree::Order.find_by_number(number) || raise(ActiveRecord::RecordNotFound)
          order.shipments.each do |shipment|
            shipment.send("#{params['status']}!".to_sym)
          end

          response do |r|
            r.element 'UpdateSuccess'
          end
        end
      end

    rescue ActiveRecord::RecordNotFound
      error_response("NOT_FOUND", "Unable to find a #{SpreeShipworks.order_class.name.demodulize.singularize} with number of '#{number}'.")
    rescue StateMachine::InvalidTransition, NoMethodError => error
      error_response("INVALID_STATUS", error.to_s)
    rescue => error
      error_response("INTERNAL_SERVER_ERROR", error.to_s)
    end
  end
end
