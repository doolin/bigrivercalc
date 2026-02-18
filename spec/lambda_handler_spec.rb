# frozen_string_literal: true

require "spec_helper"
require "bigrivercalc"
require "bigrivercalc/lambda_handler"
require "json"

RSpec.describe Bigrivercalc::LambdaHandler do
  let(:line_items) do
    [
      Bigrivercalc::BillingLineItem.new(
        service: "Amazon EC2", amount: "12.50", currency: "USD",
        period: "2025-02-01 to 2025-03-01"
      ),
      Bigrivercalc::BillingLineItem.new(
        service: "Amazon S3", amount: "2.30", currency: "USD",
        period: "2025-02-01 to 2025-03-01"
      )
    ]
  end

  before do
    allow(Bigrivercalc).to receive(:fetch_billing).and_return(line_items)
  end

  describe ".process" do
    it "returns markdown by default" do
      result = described_class.process(event: {})

      expect(result[:statusCode]).to eq(200)
      expect(result[:body]).to include("| Service | Amount | Currency |")
      expect(result[:body]).to include("Amazon EC2")
    end

    it "returns terminal format when requested" do
      result = described_class.process(event: { "format" => "terminal" })

      expect(result[:statusCode]).to eq(200)
      expect(result[:body]).to include("Amazon EC2")
      expect(result[:body]).not_to include("| Service |")
    end

    it "passes account_id to fetch_billing" do
      described_class.process(event: { "account_id" => "123456789012" })

      expect(Bigrivercalc).to have_received(:fetch_billing).with(
        time_period: nil, account_id: "123456789012"
      )
    end

    it "parses period and passes time_period" do
      described_class.process(event: { "period" => "2025-01" })

      expect(Bigrivercalc).to have_received(:fetch_billing).with(
        time_period: { start: "2025-01-01", end: "2025-02-01" },
        account_id: nil
      )
    end

    it "includes account and period in formatted output" do
      result = described_class.process(
        event: { "account_id" => "123456789012", "period" => "2025-02" }
      )

      expect(result[:body]).to include("123456789012")
    end

    context "when no billing data found" do
      before { allow(Bigrivercalc).to receive(:fetch_billing).and_return([]) }

      it "returns a message with status 200" do
        result = described_class.process(event: {})

        expect(result[:statusCode]).to eq(200)
        body = JSON.parse(result[:body])
        expect(body["message"]).to eq("No billing data found.")
      end
    end

    context "when AWS credentials are missing" do
      before do
        allow(Bigrivercalc).to receive(:fetch_billing)
          .and_raise(Aws::Errors::MissingCredentialsError.new("no creds"))
      end

      it "returns 500 with error message" do
        result = described_class.process(event: {})

        expect(result[:statusCode]).to eq(500)
        body = JSON.parse(result[:body])
        expect(body["error"]).to include("credentials")
      end
    end

    context "when AWS service error occurs" do
      before do
        allow(Bigrivercalc).to receive(:fetch_billing)
          .and_raise(Aws::Errors::ServiceError.new(nil, "throttled"))
      end

      it "returns 502 with error message" do
        result = described_class.process(event: {})

        expect(result[:statusCode]).to eq(502)
        body = JSON.parse(result[:body])
        expect(body["error"]).to eq("throttled")
      end
    end

    context "when application error occurs" do
      before do
        allow(Bigrivercalc).to receive(:fetch_billing)
          .and_raise(Bigrivercalc::Error.new("bad input"))
      end

      it "returns 400 with error message" do
        result = described_class.process(event: {})

        expect(result[:statusCode]).to eq(400)
        body = JSON.parse(result[:body])
        expect(body["error"]).to eq("bad input")
      end
    end
  end
end
