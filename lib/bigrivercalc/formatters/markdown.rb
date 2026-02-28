# frozen_string_literal: true

module Bigrivercalc
  module Formatters
    class Markdown
      def format(line_items, account_id: nil, period: nil)
        lines = []
        lines << header(account_id, period) if account_id || period
        lines << table(line_items)
        lines << total_row(line_items) if line_items.any?
        lines.compact.join("\n\n")
      end

      def format_by_ou(ou_results, period: nil)
        sections = []
        sections << "**Period:** #{period}" if period

        grand_total = 0.0
        ou_results.each do |ou, line_items|
          section = []
          ou_total = line_items.sum { |i| i.amount.to_f }
          grand_total += ou_total
          section << "### #{escape(ou.name)} (`#{ou.id}`) — #{format_amount(ou_total)}"
          if line_items.any?
            section << table(line_items)
          else
            section << "_No billing data._"
          end
          sections << section.join("\n\n")
        end

        sections << "---\n\n**Grand Total:** #{format_amount(grand_total)}"
        sections.compact.join("\n\n")
      end

      private

      def header(account_id, period)
        parts = []
        parts << "**Account:** #{account_id}" if account_id
        parts << "**Period:** #{period}" if period
        parts.join(" | ")
      end

      def table(line_items)
        return "" if line_items.empty?

        rows = [
          "| Service | Amount | Currency |",
          "| --- | --- | --- |"
        ]
        line_items.each do |item|
          rows << "| #{escape(item.service)} | #{item.amount} | #{item.currency} |"
        end
        rows.join("\n")
      end

      def total_row(line_items)
        total = line_items.sum { |i| i.amount.to_f }
        "**Total:** #{format_amount(total)}"
      end

      def format_amount(value)
        sprintf("%.2f", value)
      end

      def escape(text)
        text.to_s.gsub("|", "\\|")
      end
    end
  end
end
