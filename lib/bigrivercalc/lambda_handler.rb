# frozen_string_literal: true

require "json"

module Bigrivercalc
  class LambdaHandler
    def self.process(event:, context: nil)
      format     = event["format"] || "markdown"
      account_id = event["account_id"]
      period_str = event["period"]

      time_period = PeriodParser.parse(period_str) if period_str

      line_items = Bigrivercalc.fetch_billing(
        time_period: time_period,
        account_id: account_id
      )

      if line_items.empty?
        return response(200, JSON.generate(message: "No billing data found."))
      end

      period_label = line_items.first&.period ||
        (time_period ? "#{time_period[:start]} to #{time_period[:end]}" : nil)
      formatter_opts = { account_id: account_id, period: period_label }

      body = case format
             when "terminal"
               Bigrivercalc.format_terminal(line_items, **formatter_opts)
             else
               Bigrivercalc.format_markdown(line_items, **formatter_opts)
             end

      response(200, body)
    rescue Aws::Errors::MissingCredentialsError
      response(500, JSON.generate(error: "AWS credentials not configured."))
    rescue Aws::Errors::ServiceError => e
      response(502, JSON.generate(error: e.message))
    rescue Bigrivercalc::Error => e
      response(400, JSON.generate(error: e.message))
    end

    def self.response(status_code, body)
      { statusCode: status_code, body: body }
    end
    private_class_method :response
  end
end
