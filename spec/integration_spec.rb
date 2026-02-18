# frozen_string_literal: true

require "spec_helper"
require "json"
require "ostruct"
require "bigrivercalc"

RSpec.describe "Integration" do
  let(:fixture_path) { File.expand_path("fixtures/sample_response.json", __dir__) }
  let(:json) { JSON.parse(File.read(fixture_path)) }
  let(:mock_response) do
    OpenStruct.new(
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
  end
  let(:mock_ce_client) { instance_double(Aws::CostExplorer::Client, get_cost_and_usage: mock_response) }

  before do
    allow(Aws::CostExplorer::Client).to receive(:new).and_return(mock_ce_client)
  end

  it "fetch_billing returns parsed line items from mocked AWS response" do
    line_items = Bigrivercalc.fetch_billing

    expect(line_items.size).to eq(2)
    expect(line_items.map(&:service)).to contain_exactly("Amazon EC2", "Amazon S3")
    expect(line_items.first.amount).to eq("12.50")
  end

  it "fetch_billing with ou_id resolves accounts and filters" do
    mock_org_client = instance_double(Aws::Organizations::Client)
    allow(Aws::Organizations::Client).to receive(:new).and_return(mock_org_client)
    page = double(accounts: [
      double(id: "111111111111", status: "ACTIVE"),
      double(id: "222222222222", status: "ACTIVE")
    ])
    response = double("paginated_response")
    allow(response).to receive(:each_page).and_yield(page)
    allow(mock_org_client).to receive(:list_accounts_for_parent)
      .with(parent_id: "ou-abc-12345")
      .and_return(response)

    line_items = Bigrivercalc.fetch_billing(ou_id: "ou-abc-12345")

    expect(mock_ce_client).to have_received(:get_cost_and_usage).with(
      hash_including(
        filter: { dimensions: { key: "LINKED_ACCOUNT", values: %w[111111111111 222222222222] } }
      )
    )
    expect(line_items.size).to eq(2)
  end

  it "fetch_billing raises when both account_id and ou_id are given" do
    expect {
      Bigrivercalc.fetch_billing(account_id: "123456789012", ou_id: "ou-abc-12345")
    }.to raise_error(Bigrivercalc::Error, /Cannot specify both/)
  end

  it "fetch_billing raises when OU has no active accounts" do
    mock_org_client = instance_double(Aws::Organizations::Client)
    allow(Aws::Organizations::Client).to receive(:new).and_return(mock_org_client)
    page = double(accounts: [])
    response = double("paginated_response")
    allow(response).to receive(:each_page).and_yield(page)
    allow(mock_org_client).to receive(:list_accounts_for_parent)
      .with(parent_id: "ou-empty-000")
      .and_return(response)

    expect {
      Bigrivercalc.fetch_billing(ou_id: "ou-empty-000")
    }.to raise_error(Bigrivercalc::Error, /No active accounts/)
  end
end
