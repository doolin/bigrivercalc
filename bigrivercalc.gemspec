# frozen_string_literal: true

require_relative "lib/bigrivercalc/version"

Gem::Specification.new do |spec|
  spec.name          = "bigrivercalc"
  spec.version       = Bigrivercalc::VERSION
  spec.authors       = ["David Doolin"]
  spec.email         = [""]

  spec.summary       = "AWS billing report generator"
  spec.description   = "Generates current billing from AWS for a particular account via the Cost Explorer API."
  spec.homepage      = "https://github.com/daviddoolin/bigrivercalc"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir["{bin,lib}/**/*", "README.md"].select { |f| File.file?(f) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["bigrivercalc"]
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-costexplorer", "~> 1.0"
  spec.add_dependency "aws-sdk-organizations", "~> 1.0"
  spec.add_dependency "ostruct", "~> 0.6"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
