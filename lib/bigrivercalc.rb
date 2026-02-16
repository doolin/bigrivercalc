# frozen_string_literal: true

require "bigrivercalc/version"
require "bigrivercalc/aws_client"
require "bigrivercalc/billing_parser"
require "bigrivercalc/formatters/markdown"
require "bigrivercalc/formatters/terminal"

module Bigrivercalc
  class Error < StandardError; end

  def self.fetch_billing(time_period: nil)
    client = AwsClient.new
    response = client.get_cost_and_usage(time_period: time_period)
    BillingParser.new.parse(response)
  end

  def self.format_markdown(line_items, **opts)
    Formatters::Markdown.new.format(line_items, **opts)
  end

  def self.format_terminal(line_items, **opts)
    Formatters::Terminal.new.format(line_items, **opts)
  end
end
