# frozen_string_literal: true

module Bigrivercalc
  BillingLineItem = Struct.new(:service, :amount, :currency, :period, keyword_init: true)

  class BillingParser
    def parse(response)
      line_items = []

      (response.results_by_time || []).each do |result|
        period = format_period(result.time_period)
        (result.groups || []).each do |group|
          item = extract_line_item(group, period)
          line_items << item if item && !zero_amount?(item.amount)
        end
      end

      line_items.sort_by { |i| -i.amount.to_f }
    end

    private

    def format_period(time_period)
      return nil unless time_period

      start_date = time_period.start
      end_date = time_period.end
      [start_date, end_date].compact.join(" to ")
    end

    def extract_line_item(group, period)
      service = (group.keys || []).first || "Unknown"
      metrics = group.metrics || {}

      # Prefer BlendedCost, fall back to UnblendedCost
      metric_value = metrics["BlendedCost"] || metrics["UnblendedCost"]
      return nil unless metric_value

      amount = metric_value.amount || "0"
      currency = metric_value.unit || "USD"

      BillingLineItem.new(
        service: service,
        amount: amount,
        currency: currency,
        period: period
      )
    end

    def zero_amount?(amount_str)
      amount_str.to_s.strip == "" || amount_str.to_f.zero?
    end
  end
end
