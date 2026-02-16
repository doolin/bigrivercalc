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
- Or `~/.aws/credentials` (when using the AWS CLI profile)

Cost Explorer uses the `us-east-1` region.

## Usage

```bash
bundle exec bin/bigrivercalc
```

Or when installed as a gem:

```bash
bigrivercalc
```

## IAM Permissions

Your AWS credentials need:

- `ce:GetCostAndUsage`
- `ce:GetDimensionValues` (optional)
