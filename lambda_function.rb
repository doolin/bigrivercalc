# frozen_string_literal: true

# AWS Lambda entry point.
# Handler setting: lambda_function.handler

require "bigrivercalc"
require "bigrivercalc/lambda_handler"

def handler(event:, context:)
  Bigrivercalc::LambdaHandler.process(event: event, context: context)
end
