# frozen_string_literal: true

module Bigrivercalc
  module Formatters
    class Terminal
      RED = "\e[31m"
      RESET = "\e[0m"

      def initialize(color: true)
        @color = color && $stdout.tty?
      end

      def format(line_items, account_id: nil, period: nil)
        lines = []
        lines << header(account_id, period) if account_id || period
        lines << table(line_items)
        lines << total_row(line_items) if line_items.any?
        lines.compact.join("\n")
      end

      private

      def header(account_id, period)
        parts = []
        parts << "Account: #{account_id}" if account_id
        parts << "Period: #{period}" if period
        parts.join("  |  ")
      end

      def table(line_items)
        return "" if line_items.empty?

        max_service = [line_items.map { |i| i.service.to_s.length }.max, 7].max
        max_amount = [line_items.map { |i| i.amount.to_s.length }.max, 6].max

        rows = []
        rows << sprintf("%-#{max_service}s  %#{max_amount}s  %s", "Service", "Amount", "Currency")
        rows << "-" * (max_service + max_amount + 10)
        line_items.each do |item|
          amount_str = sprintf("%#{max_amount}s", item.amount.to_s)
          amount_str = "#{RED}#{amount_str}#{RESET}" if @color && item.amount.to_f > 100
          rows << sprintf("%-#{max_service}s  %s  %s", item.service, amount_str, item.currency)
        end
        rows.join("\n")
      end

      def total_row(line_items)
        total = line_items.sum { |i| i.amount.to_f }
        "Total: #{sprintf('%.2f', total)}"
      end
    end
  end
end
