require 'spree_core'
require 'spree_shipworks/engine'
require 'spree_shipworks/dsl'

module SpreeShipworks

  mattr_accessor :order_class

  def self.order_class
    if Setting[:use_split_shipments]
      SpreeShipworks::Shipments
    else
      SpreeShipworks::Orders
    end
  end
end
