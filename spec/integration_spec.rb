# frozen_string_literal: true

require "spec_helper"
require "json"
require "ostruct"
require "bigrivercalc"

RSpec.describe "Integration" do
  it "fetch_billing returns parsed line items from mocked AWS response" do
    fixture_path = File.expand_path("fixtures/sample_response.json", __dir__)
    json = JSON.parse(File.read(fixture_path))
    mock_response = OpenStruct.new(
      results_by_time: json["ResultsByTime"].map { |rbt|
        OpenStruct.new(
          time_period: OpenStruct.new(start: rbt["TimePeriod"]["Start"], end: rbt["TimePeriod"]["End"]),
          total: rbt["Total"],
          groups: (rbt["Groups"] || []).map { |g|
            OpenStruct.new(
              keys: g["Keys"],
              metrics: (g["Metrics"] || {}).transform_values { |m| OpenStruct.new(amount: m["Amount"], unit: m["Unit"]) }
            )
          },
          estimated: rbt["Estimated"]
        )
      }
    )

    mock_client = instance_double(Aws::CostExplorer::Client, get_cost_and_usage: mock_response)
    allow(Aws::CostExplorer::Client).to receive(:new).and_return(mock_client)

    line_items = Bigrivercalc.fetch_billing

    expect(line_items.size).to eq(2)
    expect(line_items.map(&:service)).to contain_exactly("Amazon EC2", "Amazon S3")
    expect(line_items.first.amount).to eq("12.50")
  end
end
