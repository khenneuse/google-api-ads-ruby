# Encoding: utf-8
#
# This is auto-generated code, changes will be overwritten.
#
# Copyright:: Copyright 2012, Google Inc. All Rights Reserved.
# License:: Licensed under the Apache License, Version 2.0.
#
# Code generated by AdsCommon library 0.9.2 on 2013-07-10 22:04:15.

require 'ads_common/savon_service'
require 'adwords_api/v201306/geo_location_service_registry'

module AdwordsApi; module V201306; module GeoLocationService
  class GeoLocationService < AdsCommon::SavonService
    def initialize(config, endpoint)
      namespace = 'https://adwords.google.com/api/adwords/cm/v201306'
      super(config, endpoint, namespace, :v201306)
    end

    def get(*args, &block)
      return execute_action('get', args, &block)
    end

    private

    def get_service_registry()
      return GeoLocationServiceRegistry
    end

    def get_module()
      return AdwordsApi::V201306::GeoLocationService
    end
  end
end; end; end
