# frozen_string_literal: true

require "date"

module Bigrivercalc
  class PeriodParser
    # Parses period strings like "2025-02", "current", "last-month" into { start:, end: }
    def self.parse(period_str)
      return nil if period_str.nil? || period_str.to_s.strip == ""

      case period_str.to_s.downcase.strip
      when "current", "month", "mtd"
        current_month
      when "last-month", "previous"
        last_month
      when /^\d{4}-\d{2}$/  # YYYY-MM
        parse_month(period_str)
      else
        nil
      end
    end

    def self.current_month
      now = Time.now.utc
      start_date = Date.new(now.year, now.month, 1)
      end_date = start_date >> 1
      { start: start_date.strftime("%Y-%m-%d"), end: end_date.strftime("%Y-%m-%d") }
    end

    def self.last_month
      now = Time.now.utc
      start_date = Date.new(now.year, now.month, 1) << 1
      end_date = start_date >> 1
      { start: start_date.strftime("%Y-%m-%d"), end: end_date.strftime("%Y-%m-%d") }
    end

    def self.parse_month(period_str)
      year, month = period_str.split("-").map(&:to_i)
      return nil unless (1..12).cover?(month)

      start_date = Date.new(year, month, 1)
      end_date = start_date >> 1
      { start: start_date.strftime("%Y-%m-%d"), end: end_date.strftime("%Y-%m-%d") }
    end
  end
end
