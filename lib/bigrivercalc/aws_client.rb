# frozen_string_literal: true

require "aws-sdk-costexplorer"

module Bigrivercalc
  class AwsClient
    COST_EXPLORER_REGION = "us-east-1"

    def initialize(region: COST_EXPLORER_REGION)
      @client = Aws::CostExplorer::Client.new(region: region)
    end

    def get_cost_and_usage(time_period: nil, granularity: "MONTHLY")
      @client.get_cost_and_usage(
        time_period: time_period || default_time_period,
        granularity: granularity,
        metrics: ["BlendedCost", "UnblendedCost"],
        group_by: [{ type: "DIMENSION", key: "SERVICE" }]
      )
    end

    private

    def default_time_period
      now = Time.now.utc
      start_date = Date.new(now.year, now.month, 1).strftime("%Y-%m-%d")
      end_date = (Date.new(now.year, now.month, 1) >> 1).strftime("%Y-%m-%d")
      { start: start_date, end: end_date }
    end
  end
end
