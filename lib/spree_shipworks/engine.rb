# frozen_string_literal: true

module SpreeShipworks
  class Engine < Rails::Engine
    require 'spree/core'
    # isolate_namespace Spree
    engine_name 'spree_shipworks'
    isolate_namespace SpreeShipworks

    config.autoload_paths += %W[#{config.root}/lib]

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'spree.shipworks.environment', before: :load_config_initializers do |_app|
      SpreeShipworks::Config = Spree::ShipworksConfiguration.new
    end
  end
end
