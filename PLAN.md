# Plan: AWS Billing Report Tool (bigrivercalc)

**Status: Complete** (Feb 2025)

---

## Overview

Build a Ruby CLI that fetches AWS billing data via the Cost Explorer API, filters to non-zero amounts only, and outputs in Markdown (and optionally terminal-friendly) format.

---

## Phase 1: Project Setup

1. **Project structure**
   - `Gemfile` – `aws-sdk-costexplorer`, `bundler`
   - `bigrivercalc.gemspec` – if you want it as a gem
   - `lib/bigrivercalc.rb` – main entry point
   - `lib/bigrivercalc/` – core modules
   - `bin/bigrivercalc` – executable script
   - `README.md` – usage and setup

2. **Dependencies**
   - `aws-sdk-costexplorer` – Cost Explorer API
   - Ruby ≥ 2.7

3. **Configuration**
   - AWS credentials via env vars (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`) or `~/.aws/credentials`
   - Optional config file for account ID, time range, output format

---

## Phase 2: Core Logic

4. **AWS client**
   - `lib/bigrivercalc/aws_client.rb`
   - Initialize `Aws::CostExplorer::Client` (region `us-east-1` for Cost Explorer)
   - Call `get_cost_and_usage` with:
     - `TimePeriod` – e.g. current month
     - `Granularity` – `MONTHLY` or `DAILY`
     - `Metrics` – `BlendedCost`, `UnblendedCost`, etc.
     - `GroupBy` – e.g. `SERVICE` to group by service

5. **Parser / filter**
   - `lib/bigrivercalc/billing_parser.rb`
   - Parse `ResultsByTime` from the response
   - Extract cost entries and filter out zero amounts
   - Normalize into a simple structure (service name, amount, currency, time period)

6. **Data model**
   - Simple struct or hash for each line item: `{ service:, amount:, currency:, period: }`
   - Aggregate structure suitable for both Markdown and terminal output

---

## Phase 3: Output Formatters

7. **Markdown formatter**
   - `lib/bigrivercalc/formatters/markdown.rb`
   - Table: Service | Amount | Currency
   - Optional header with account ID and time range
   - Optional total row

8. **Terminal formatter**
   - `lib/bigrivercalc/formatters/terminal.rb`
   - Plain text or ASCII table
   - Optional color for amounts (e.g. red for high costs)
   - Works well in a terminal (no markdown rendering)

---

## Phase 4: CLI & Integration

9. **CLI**
   - `bin/bigrivercalc`
   - Options: `--format` (markdown/terminal), `--account`, `--period` (e.g. month-to-date)
   - Default: Markdown to stdout
   - Exit codes: 0 success, 1 on errors

10. **Error handling**
    - Handle missing credentials, API errors, empty results
    - Clear error messages and non-zero exit codes

---

## Phase 5: Polish

11. **IAM**
    - Document required IAM permissions (e.g. `ce:GetCostAndUsage`, `ce:GetDimensionValues`)

12. **Testing**
    - Unit tests for parser and formatters (with fixture JSON)
    - Optional integration tests with mocked AWS client

13. **Documentation**
    - README: install, configure, usage, IAM, examples

---

## Suggested File Layout

```
bigrivercalc/
├── Gemfile
├── README.md
├── PLAN.md
├── bin/
│   └── bigrivercalc
├── lib/
│   ├── bigrivercalc.rb
│   └── bigrivercalc/
│       ├── aws_client.rb
│       ├── billing_parser.rb
│       └── formatters/
│           ├── markdown.rb
│           └── terminal.rb
├── spec/                    # optional
│   ├── billing_parser_spec.rb
│   └── fixtures/
│       └── sample_response.json
└── bigrivercalc.gemspec     # optional
```

---

## Implementation Order

1. Project setup (Gemfile, structure)
2. AWS client + `get_cost_and_usage` call
3. Parser + non-zero filter
4. Markdown formatter
5. CLI wiring
6. Terminal formatter
7. Error handling and docs

---

## Notes

- **CLI sanity check:** For each stage, ensure `bundle exec bin/bigrivercalc` (or equivalent) runs. Use `--stub` or mocks until AWS is hooked up.
- Cost Explorer is in `us-east-1`; other regions may not work.
- Cost data can lag by up to 24 hours.
- `GetCostAndUsage` returns nested JSON; parsing will focus on `ResultsByTime` and `Groups`.
- IAM: `ce:GetCostAndUsage` (and possibly `ce:GetDimensionValues`) on the relevant account.

---

## Future Work

**Shipping**
- Publish to RubyGems (`gem push`)
- GitHub release and version tag

**Features**
- `--output FILE` – write to file instead of stdout
- `--json` – machine-readable output format
- More period formats (e.g. date ranges)
- `--profile` – select AWS profile from CLI
- `--output SQL`
- `operate as a lambda`

**Hardening**
- CI (e.g. GitHub Actions) to run specs
- Rakefile with `rake test` / `rake build`
- RuboCop or other linter
