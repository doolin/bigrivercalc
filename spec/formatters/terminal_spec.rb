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
end
