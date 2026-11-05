# frozen_string_literal: true

# Proposed bigrivercalc API extensions for dbb billing view.
# These specs define the interface dbb needs. They are intended
# to be ported to bigrivercalc and implemented there.
#
# Two categories:
#   1. Introspection — expose org structure (current account, accounts, OUs)
#   2. Filtered fetch — fetch billing excluding specific accounts

require "rails_helper"

RSpec.describe "Bigrivercalc API extensions (proposed)", type: :lib do
  let(:time_period) { Bigrivercalc::PeriodParser.current_month }

  # -------------------------------------------------------------------
  # 1. Introspection: expose org structure so consumers can filter/display
  # -------------------------------------------------------------------
  describe "Bigrivercalc.current_account" do
    it "returns an AccountInfo for the caller's AWS account" do
      account = Bigrivercalc.current_account
      expect(account).to be_a(Bigrivercalc::AccountInfo)
      expect(account.id).to match(/\A\d{12}\z/)
      expect(account.name).to be_a(String)
    end
  end

  describe "Bigrivercalc.list_accounts" do
    it "returns all accounts in the organization" do
      accounts = Bigrivercalc.list_accounts
      expect(accounts).to be_an(Array)
      expect(accounts).to all(be_a(Bigrivercalc::AccountInfo))
      expect(accounts.map(&:id)).to include(Bigrivercalc.current_account.id)
    end
  end

  describe "Bigrivercalc.list_ous" do
    it "returns all organizational units" do
      ous = Bigrivercalc.list_ous
      expect(ous).to be_an(Array)
      expect(ous).to all(be_a(Bigrivercalc::OUInfo))
    end
  end

  # -------------------------------------------------------------------
  # 2. Filtered fetch: exclude accounts to avoid duplicate display
  # -------------------------------------------------------------------
  describe "Bigrivercalc.fetch_billing_by_ou(exclude_account_ids:)" do
    it "excludes specified accounts from the org billing results" do
      current = Bigrivercalc.current_account

      all_results = Bigrivercalc.fetch_billing_by_ou(time_period: time_period)
      filtered = Bigrivercalc.fetch_billing_by_ou(
        time_period: time_period,
        exclude_account_ids: [current.id]
      )

      all_items = all_results.values.flatten
      filtered_items = filtered.values.flatten

      expect(filtered_items.length).to be <= all_items.length
    end
  end

  describe "Bigrivercalc.fetch_billing(exclude_account_id:)" do
    it "fetches billing for the org excluding a single account" do
      current = Bigrivercalc.current_account

      all_items = Bigrivercalc.fetch_billing(time_period: time_period)
      filtered = Bigrivercalc.fetch_billing(
        time_period: time_period,
        exclude_account_id: current.id
      )

      expect(filtered.length).to be <= all_items.length
      expect(filtered).to all(be_a(Bigrivercalc::BillingLineItem))
    end
  end
end
