#!/usr/bin/ruby
#
# Author:: api.sgomes@gmail.com (Sérgio Gomes)
#
# Copyright:: Copyright 2011, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# This example illustrates how to retrieve all the paused campaigns for an
# account.
#
# Tags: CampaignService.get

gem 'google-adwords-api'
require 'adwords_api'

API_VERSION = :v201101

def get_all_paused_campaigns()
  # AdwordsApi::Api will read a config file from ENV['HOME']/adwords_api.yml
  # when called without parameters.
  adwords = AdwordsApi::Api.new

  # To enable logging of SOAP requests, set the log_level value to 'DEBUG' in
  # the configuration file or provide your own logger:
  # adwords.logger = Logger.new('adwords_xml.log')

  campaign_srv = adwords.service(:CampaignService, API_VERSION)

  # Get all the paused campaigns for this account.
  selector = {
    :fields => ['Id', 'Name', 'Status'],
    :ordering => [{:field => 'Name', :sort_order => 'ASCENDING'}],
    :predicates => [{
      :field => 'Status',
      :operator => 'IN',
      :values => ['PAUSED']
    }]
  }
  response = campaign_srv.get(selector)

  if response and response[:entries]
    campaigns = response[:entries]
    campaigns.each do |campaign|
      puts "Campaign name is \"#{campaign[:name]}\", id is #{campaign[:id]} " +
          "and status is \"#{campaign[:status]}\"."
    end
  else
    puts "No campaigns were found."
  end
end

if __FILE__ == $0
  begin
    get_all_paused_campaigns()

  # Connection error. Likely transitory.
  rescue Errno::ECONNRESET, SOAP::HTTPStreamError, SocketError => e
    puts 'Connection Error: %s' % e
    puts 'Source: %s' % e.backtrace.first

  # API Error.
  rescue AdwordsApi::Errors::ApiException => e
    puts 'API Exception caught.'
    puts 'Message: %s' % e.message
    puts 'Code: %d' % e.code if e.code
    puts 'Trigger: %s' % e.trigger if e.trigger
    puts 'Errors:'
    if e.errors
      e.errors.each_with_index do |error, index|
        puts ' %d. Error type is %s. Fields:' % [index + 1, error[:xsi_type]]
        error.each_pair do |field, value|
          if field != :xsi_type
            puts '     %s: %s' % [field, value]
          end
        end
      end
    end
  end
end
