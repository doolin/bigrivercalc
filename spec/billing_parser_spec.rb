# frozen_string_literal: true

require "spec_helper"
require "json"
require "ostruct"
require "bigrivercalc/billing_parser"

RSpec.describe Bigrivercalc::BillingParser do
  let(:parser) { described_class.new }

  describe "#parse" do
    let(:fixture_path) { File.expand_path("fixtures/sample_response.json", __dir__) }
    let(:response) do
      json = JSON.parse(File.read(fixture_path))
      # Convert to struct-like objects that match AWS SDK response shape
      OpenStruct.new(
        results_by_time: json["ResultsByTime"].map do |rbt|
          OpenStruct.new(
            time_period: OpenStruct.new(start: rbt["TimePeriod"]["Start"], end: rbt["TimePeriod"]["End"]),
            total: rbt["Total"],
            groups: rbt["Groups"].map do |g|
              OpenStruct.new(
                keys: g["Keys"],
                metrics: g["Metrics"].transform_values { |m| OpenStruct.new(amount: m["Amount"], unit: m["Unit"]) }
              )
            end,
            estimated: rbt["Estimated"]
          )
        end
      )
    end

    it "returns only non-zero line items" do
      items = parser.parse(response)
      expect(items.map(&:service)).to contain_exactly("Amazon EC2", "Amazon S3")
    end

    it "sorts by amount descending" do
      items = parser.parse(response)
      expect(items.first.service).to eq("Amazon EC2")
      expect(items.first.amount).to eq("12.50")
      expect(items.last.service).to eq("Amazon S3")
      expect(items.last.amount).to eq("2.30")
    end

    it "includes period, amount, and currency" do
      items = parser.parse(response)
      expect(items.first.period).to eq("2025-02-01 to 2025-03-01")
      expect(items.first.currency).to eq("USD")
    end
  end
end
