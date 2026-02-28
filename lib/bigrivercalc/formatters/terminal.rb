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

      def format_by_ou(ou_results, period: nil)
        sections = []
        sections << "Period: #{period}" if period

        grand_total = 0.0
        ou_results.each do |ou, line_items|
          section = []
          ou_total = line_items.sum { |i| i.amount.to_f }
          grand_total += ou_total
          section << "#{ou.name} (#{ou.id}) — #{sprintf('%.2f', ou_total)}"
          section << "=" * section.last.length
          if line_items.any?
            section << table(line_items)
          else
            section << "(no billing data)"
          end
          sections << section.join("\n")
        end

        sections << "Grand Total: #{sprintf('%.2f', grand_total)}"
        sections.compact.join("\n\n")
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
