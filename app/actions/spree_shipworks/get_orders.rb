# frozen_string_literal: true

module SpreeShipworks
  class GetOrders
    include Dsl

    def call(params)
      response do |r|
        r.element 'Orders' do |r|
          ::SpreeShipworks.order_class.since_in_batches(params['start'], params['maxcount']) do |order|
            order.to_shipworks_xml(r)
          end
        end
      end
    rescue ArgumentError => e
      error_response('INVALID_VARIABLE', e.to_s + "\n" + e.backtrace.join("\n"))
    rescue StandardError => e
      Rails.logger.error(e.to_s)
      Rails.logger.error(e.backtrace.join("\n"))
      error_response('INTERNAL_SERVER_ERROR', e.to_s)
    end
  end
end
