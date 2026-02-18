# frozen_string_literal: true

require "bigrivercalc/version"
require "bigrivercalc/aws_client"
require "bigrivercalc/billing_parser"
require "bigrivercalc/org_client"
require "bigrivercalc/period_parser"
require "bigrivercalc/formatters/markdown"
require "bigrivercalc/formatters/terminal"

module Bigrivercalc
  class Error < StandardError; end

  def self.fetch_billing(time_period: nil, account_id: nil, ou_id: nil)
    if account_id && ou_id
      raise Error, "Cannot specify both --account and --ou"
    end

    account_ids = if ou_id
      ids = OrgClient.new.list_account_ids(ou_id)
      raise Error, "No active accounts found in OU #{ou_id}" if ids.empty?
      ids
    elsif account_id
      [account_id]
    end

    filter = if account_ids
      { dimensions: { key: "LINKED_ACCOUNT", values: account_ids } }
    end

    client = AwsClient.new
    response = client.get_cost_and_usage(time_period: time_period, filter: filter)
    BillingParser.new.parse(response)
  end

  def self.format_markdown(line_items, **opts)
    Formatters::Markdown.new.format(line_items, **opts)
  end

  def self.format_terminal(line_items, **opts)
    Formatters::Terminal.new.format(line_items, **opts)
  end
end
