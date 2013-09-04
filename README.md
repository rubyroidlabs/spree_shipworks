SpreeShipworks
==============

This extension implements the ShipWorks 3.0 API endpoint (/shipworks/api) on
your Spree Store, as defined in “ShipWorks 3.0: Store Integration Guide: version
1.0”.


Installation
============

Add to your Gemfile:

    # spree 1.3
    gem 'spree_shipworks',
        :github => 'fantree/spree_shipworks',
        :branch => '1-3-stable'

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test_app
    $ bundle exec rspec spec

Copyright (c) 2013 [name of extension creator], released under the New BSD License
