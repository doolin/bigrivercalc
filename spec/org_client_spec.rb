# frozen_string_literal: true

require "spec_helper"
require "bigrivercalc"

RSpec.describe Bigrivercalc::OrgClient do
  let(:mock_client) { instance_double(Aws::Organizations::Client) }

  before do
    allow(Aws::Organizations::Client).to receive(:new).and_return(mock_client)
  end

  def stub_pages(ou_id, *pages)
    response = double("paginated_response")
    stub = allow(response).to receive(:each_page)
    pages.each { |page| stub = stub.and_yield(page) }
    allow(mock_client).to receive(:list_accounts_for_parent)
      .with(parent_id: ou_id)
      .and_return(response)
  end

  describe "#list_account_ids" do
    it "returns active account IDs for the given OU" do
      page = double(accounts: [
        double(id: "111111111111", status: "ACTIVE"),
        double(id: "222222222222", status: "ACTIVE")
      ])
      stub_pages("ou-abc-12345", page)

      result = described_class.new.list_account_ids("ou-abc-12345")

      expect(result).to eq(%w[111111111111 222222222222])
    end

    it "filters out suspended accounts" do
      page = double(accounts: [
        double(id: "111111111111", status: "ACTIVE"),
        double(id: "333333333333", status: "SUSPENDED")
      ])
      stub_pages("ou-abc-12345", page)

      result = described_class.new.list_account_ids("ou-abc-12345")

      expect(result).to eq(%w[111111111111])
    end

    it "handles paginated results" do
      page1 = double(accounts: [double(id: "111111111111", status: "ACTIVE")])
      page2 = double(accounts: [double(id: "222222222222", status: "ACTIVE")])
      stub_pages("ou-abc-12345", page1, page2)

      result = described_class.new.list_account_ids("ou-abc-12345")

      expect(result).to eq(%w[111111111111 222222222222])
    end

    it "returns empty array when OU has no active accounts" do
      page = double(accounts: [])
      stub_pages("ou-abc-12345", page)

      result = described_class.new.list_account_ids("ou-abc-12345")

      expect(result).to eq([])
    end
  end
end
