# frozen_string_literal: true

require "bigrivercalc/version"
require "bigrivercalc/aws_client"
require "bigrivercalc/billing_parser"

module Bigrivercalc
  class Error < StandardError; end

  def self.fetch_billing(time_period: nil)
    client = AwsClient.new
    response = client.get_cost_and_usage(time_period: time_period)
    BillingParser.new.parse(response)
  end
end
