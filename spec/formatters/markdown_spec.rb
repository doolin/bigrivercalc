# frozen_string_literal: true

require "spec_helper"
require "bigrivercalc/formatters/markdown"

RSpec.describe Bigrivercalc::Formatters::Markdown do
  let(:formatter) { described_class.new }
  let(:line_items) do
    [
      Bigrivercalc::BillingLineItem.new(service: "Amazon EC2", amount: "12.50", currency: "USD", period: "2025-02-01 to 2025-03-01"),
      Bigrivercalc::BillingLineItem.new(service: "Amazon S3", amount: "2.30", currency: "USD", period: "2025-02-01 to 2025-03-01")
    ]
  end

  describe "#format" do
    it "outputs a markdown table with Service, Amount, Currency" do
      output = formatter.format(line_items)
      expect(output).to include("| Service | Amount | Currency |")
      expect(output).to include("| Amazon EC2 | 12.50 | USD |")
      expect(output).to include("| Amazon S3 | 2.30 | USD |")
    end

    it "includes total row" do
      output = formatter.format(line_items)
      expect(output).to include("**Total:** 14.80")
    end

    it "includes header when account_id or period given" do
      output = formatter.format(line_items, account_id: "123456789", period: "Feb 2025")
      expect(output).to include("**Account:** 123456789")
      expect(output).to include("**Period:** Feb 2025")
    end

    it "handles empty line items" do
      output = formatter.format([])
      expect(output).not_to include("| Service |")
      expect(output).to eq("")
    end
  end

  describe "#format_by_ou" do
    let(:ou_results) do
      {
        Bigrivercalc::OUInfo.new(id: "ou-abc1-11111111", name: "Engineering") => line_items,
        Bigrivercalc::OUInfo.new(id: "ou-abc1-22222222", name: "Marketing") => []
      }
    end

    it "includes a section for each OU with name and ID" do
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("Engineering")
      expect(output).to include("ou-abc1-11111111")
      expect(output).to include("Marketing")
      expect(output).to include("ou-abc1-22222222")
    end

    it "shows billing table for OUs with data" do
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("| Amazon EC2 | 12.50 | USD |")
    end

    it "shows no-data message for empty OUs" do
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("No billing data")
    end

    it "includes grand total" do
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("**Grand Total:** 14.80")
    end

    it "includes period when given" do
      output = formatter.format_by_ou(ou_results, period: "Feb 2025")
      expect(output).to include("**Period:** Feb 2025")
    end
  end
end
