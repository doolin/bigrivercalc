# Bigrivercalc

A small, Ruby-based application which generates the current billing from AWS for a particular account. The API call returns JSON, which is parsed and filtered to report only non-zero billing amounts. Output formats: Markdown and terminal-friendly.

## Requirements

- Ruby >= 2.7
- AWS credentials with Cost Explorer access

## Installation

```bash
bundle install
```

Or install as a gem (after building):

```bash
gem build bigrivercalc.gemspec
gem install bigrivercalc-0.1.0.gem
```

## Configuration

AWS credentials are read from:

- Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
- Or `~/.aws/credentials` (when using the AWS CLI)

Cost Explorer uses the `us-east-1` region.

## Usage

Run directly (no `bundle exec` needed):

```bash
./bin/bigrivercalc
```

Or when installed as a gem:

```bash
bigrivercalc
```

### Options

| Option | Description |
|--------|-------------|
| `-f`, `--format FORMAT` | Output format: `markdown` or `terminal` (default: markdown) |
| `--stub` | Use fixture data instead of calling AWS (for testing) |
| `-a`, `--account ID` | Filter by AWS account ID |
| `-p`, `--period PERIOD` | Time period: `YYYY-MM`, `current`, `last-month` |
| `-h`, `--help` | Show help |

### Examples

```bash
# Current month, markdown (default)
./bin/bigrivercalc

# Terminal format
./bin/bigrivercalc --format terminal

# Specific month
./bin/bigrivercalc --period 2025-01

# Filter by account
./bin/bigrivercalc --account 123456789012

# Sanity check without AWS credentials
./bin/bigrivercalc --stub
```

## IAM Permissions

Your AWS credentials need the following permissions:

| Permission | Required | Description |
|------------|----------|-------------|
| `ce:GetCostAndUsage` | Yes | Retrieve cost and usage metrics |
| `ce:GetDimensionValues` | No | Optional; used for dimension lookups |

Example IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage"
      ],
      "Resource": "*"
    }
  ]
}
```

## Development

```bash
bundle install
bundle exec rspec
./bin/bigrivercalc --stub   # Sanity check
```
