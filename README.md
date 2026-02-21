# Bigrivercalc

A small, Ruby-based application which generates the current billing from AWS for a particular account or organizational unit. The API call returns JSON, which is parsed and filtered to report only non-zero billing amounts. Output formats: Markdown and terminal-friendly. Can also run as an AWS Lambda.

## Requirements

- Ruby >= 2.7
- AWS credentials with Cost Explorer access
- For OU filtering: AWS Organizations access from the management account

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

- Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `~/.aws/credentials` with `AWS_PROFILE`
- IAM role (when running on EC2 or Lambda)

Cost Explorer uses the `us-east-1` region internally. You do not need to set a region.

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
| `-a`, `--account ID` | Filter by a single AWS account ID |
| `--ou OU_ID` | Filter by AWS Organizations OU (aggregates all active accounts in the OU) |
| `-p`, `--period PERIOD` | Time period: `YYYY-MM`, `current`, `last-month` |
| `-h`, `--help` | Show help |

`--account` and `--ou` are mutually exclusive. If neither is specified, billing is reported for the entire payer account.

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

# Filter by organizational unit
./bin/bigrivercalc --ou ou-abc1-23456789

# Combine OU with a period
./bin/bigrivercalc --ou ou-abc1-23456789 --period last-month --format terminal

# Using a named AWS profile
AWS_PROFILE=billing ./bin/bigrivercalc

# Sanity check without AWS credentials
./bin/bigrivercalc --stub
```

## OU Filtering (Sub-organizations)

The `--ou` option uses AWS Organizations to list all active accounts under a given Organizational Unit, then queries Cost Explorer for the aggregate billing across those accounts.

### How it works

1. Calls `organizations:ListAccountsForParent` with the OU ID
2. Collects all account IDs where `status == "ACTIVE"`
3. Passes those IDs as a `LINKED_ACCOUNT` dimension filter to `ce:GetCostAndUsage`
4. Returns billing grouped by service, with zero-cost services filtered out

### Finding your OU ID

```bash
# List the root
aws organizations list-roots

# List OUs under the root (or under another OU)
aws organizations list-organizational-units-for-parent --parent-id r-abc1

# List accounts in an OU (to verify)
aws organizations list-accounts-for-parent --parent-id ou-abc1-23456789
```

OU IDs look like `ou-xxxx-xxxxxxxx`. The root ID looks like `r-xxxx`.

### Requirements

- Must be run from the **management account** (or a delegated administrator account)
- Credentials must have both Cost Explorer and Organizations permissions

## AWS Lambda

Bigrivercalc can run as an AWS Lambda function.

### Handler

Set the Lambda handler to: `lambda_function.handler`

### Event format

```json
{
  "format": "markdown",
  "account_id": "123456789012",
  "period": "current"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `format` | No | `markdown` or `terminal` (default: markdown) |
| `account_id` | No | Filter by a single account ID |
| `ou_id` | No | Filter by OU (mutually exclusive with `account_id`) |
| `period` | No | `YYYY-MM`, `current`, `last-month` |

### Response

```json
{
  "statusCode": 200,
  "body": "| Service | Amount | Currency |\n..."
}
```

Error responses return `statusCode` 400/500/502 with a JSON body containing an `error` field.

## IAM Permissions

| Permission | Required | Used by |
|------------|----------|---------|
| `ce:GetCostAndUsage` | Yes | Core billing query |
| `ce:GetDimensionValues` | No | Optional dimension lookups |
| `organizations:ListAccountsForParent` | Only with `--ou` | OU account enumeration |

### Minimal policy (billing only)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ce:GetCostAndUsage",
      "Resource": "*"
    }
  ]
}
```

### Policy with OU support

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "organizations:ListAccountsForParent"
      ],
      "Resource": "*"
    }
  ]
}
```

## Manual Verification

Use these steps to verify the tool is working correctly against real AWS.

### 1. Sanity check (no AWS needed)

```bash
./bin/bigrivercalc --stub
./bin/bigrivercalc --stub --format terminal
```

Expected: fixture data with Amazon EC2 and Amazon S3 line items.

### 2. Basic billing

```bash
./bin/bigrivercalc --period current
```

Expected: non-zero services for the current month. Compare against the AWS Cost Explorer console.

### 3. Single account filter

```bash
./bin/bigrivercalc --account <ACCOUNT_ID> --period 2025-01
```

Expected: only services billed to that account. Cross-check in the console by filtering to the same account and month.

### 4. OU filtering

```bash
# First, verify what accounts are in the OU
aws organizations list-accounts-for-parent --parent-id <OU_ID> \
  --query 'Accounts[?Status==`ACTIVE`].Id' --output text

# Then run bigrivercalc
./bin/bigrivercalc --ou <OU_ID> --period current
```

Expected: billing aggregated across all active accounts in the OU. The total should match the sum of running the tool individually for each account in the OU:

```bash
# Spot-check: run for one account in the OU
./bin/bigrivercalc --account <ONE_ACCOUNT_FROM_OU> --period current
```

### 5. Edge cases

```bash
# Account with no spend
./bin/bigrivercalc --account <DORMANT_ACCOUNT_ID> --period current
# Expected: "No billing data found for the specified period." on stderr, exit 1

# --account and --ou together (should error)
./bin/bigrivercalc --account 123 --ou ou-abc
# Expected: "Error: Cannot specify both --account and --ou" on stderr, exit 1

# Missing credentials
AWS_ACCESS_KEY_ID= AWS_SECRET_ACCESS_KEY= ./bin/bigrivercalc
# Expected: credentials error on stderr, exit 1
```

## Development

```bash
bundle install
bundle exec rspec
./bin/bigrivercalc --stub   # Sanity check
```
