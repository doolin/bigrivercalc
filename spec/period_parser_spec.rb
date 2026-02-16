# frozen_string_literal: true

require "spec_helper"
require "bigrivercalc/period_parser"

RSpec.describe Bigrivercalc::PeriodParser do
  describe ".parse" do
    it "parses YYYY-MM format" do
      result = described_class.parse("2025-02")
      expect(result).to eq({ start: "2025-02-01", end: "2025-03-01" })
    end

    it "parses current month" do
      result = described_class.parse("current")
      expect(result[:start]).to match(/\d{4}-\d{2}-01/)
      expect(result[:end]).to match(/\d{4}-\d{2}-\d{2}/)
    end

    it "parses last-month" do
      result = described_class.parse("last-month")
      expect(result[:start]).to match(/\d{4}-\d{2}-01/)
      expect(result[:end]).to match(/\d{4}-\d{2}-\d{2}/)
    end

    it "returns nil for invalid format" do
      expect(described_class.parse("invalid")).to be_nil
      expect(described_class.parse("")).to be_nil
      expect(described_class.parse(nil)).to be_nil
    end
  end
end
