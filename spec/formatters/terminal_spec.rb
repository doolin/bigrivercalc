# frozen_string_literal: true

require "spec_helper"
require "bigrivercalc/formatters/terminal"

RSpec.describe Bigrivercalc::Formatters::Terminal do
  let(:line_items) do
    [
      Bigrivercalc::BillingLineItem.new(service: "Amazon EC2", amount: "12.50", currency: "USD", period: nil),
      Bigrivercalc::BillingLineItem.new(service: "Amazon S3", amount: "2.30", currency: "USD", period: nil)
    ]
  end

  describe "#format" do
    it "outputs a plain text table" do
      formatter = described_class.new(color: false)
      output = formatter.format(line_items)
      expect(output).to include("Service")
      expect(output).to include("Amount")
      expect(output).to include("Amazon EC2")
      expect(output).to include("12.50")
      expect(output).to include("Amazon S3")
      expect(output).to include("2.30")
    end

    it "includes total row" do
      formatter = described_class.new(color: false)
      output = formatter.format(line_items)
      expect(output).to include("Total: 14.80")
    end

    it "includes header when account_id or period given" do
      formatter = described_class.new(color: false)
      output = formatter.format(line_items, account_id: "123456789", period: "Feb 2025")
      expect(output).to include("Account: 123456789")
      expect(output).to include("Period: Feb 2025")
    end

    it "handles empty line items" do
      formatter = described_class.new(color: false)
      output = formatter.format([])
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

    it "includes a section for each OU" do
      formatter = described_class.new(color: false)
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("Engineering")
      expect(output).to include("ou-abc1-11111111")
      expect(output).to include("Marketing")
      expect(output).to include("ou-abc1-22222222")
    end

    it "shows table for OUs with data" do
      formatter = described_class.new(color: false)
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("Amazon EC2")
      expect(output).to include("12.50")
    end

    it "shows no-data message for empty OUs" do
      formatter = described_class.new(color: false)
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("no billing data")
    end

    it "includes grand total" do
      formatter = described_class.new(color: false)
      output = formatter.format_by_ou(ou_results)
      expect(output).to include("Grand Total: 14.80")
    end
  end
end
