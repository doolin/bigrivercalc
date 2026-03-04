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

  # Returns a hash of { OUInfo => [BillingLineItem, ...] } for each account in the org.
  # Accounts are discovered from all OUs under root plus accounts directly under root.
  def self.fetch_billing_by_ou(time_period: nil)
    org = OrgClient.new
    root = org.root_id

    # Collect all accounts: from each OU and directly under root
    all_accounts = []
    ous = org.list_ous(root)
    ous.each do |ou|
      all_accounts.concat(org.list_accounts(ou.id))
    end
    all_accounts.concat(org.list_accounts(root))

    raise Error, "No accounts found in organization" if all_accounts.empty?

    client = AwsClient.new
    parser = BillingParser.new

    results = {}
    all_accounts.each do |account|
      entry = OUInfo.new(id: account.id, name: account.name)
      filter = { dimensions: { key: "LINKED_ACCOUNT", values: [account.id] } }
      response = client.get_cost_and_usage(time_period: time_period, filter: filter)
      results[entry] = parser.parse(response)
    end
    results
  end

  def self.format_markdown(line_items, **opts)
    Formatters::Markdown.new.format(line_items, **opts)
  end

  def self.format_terminal(line_items, **opts)
    Formatters::Terminal.new.format(line_items, **opts)
  end

  def self.format_markdown_by_ou(ou_results, **opts)
    Formatters::Markdown.new.format_by_ou(ou_results, **opts)
  end

  def self.format_terminal_by_ou(ou_results, **opts)
    Formatters::Terminal.new.format_by_ou(ou_results, **opts)
  end
end
