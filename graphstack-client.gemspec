# frozen_string_literal: true

require_relative "lib/graphstack/version"

Gem::Specification.new do |spec|
  spec.name = "graphstack-client"
  spec.version = Graphstack::VERSION
  spec.authors = ["Your Team"]
  spec.email = ["team@example.com"]

  spec.summary = "Ruby client for Graphstack messaging API"
  spec.description = "Client library for Graphstack messaging infrastructure"
  spec.homepage = "https://github.com/genevere-inc/graphstack-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "svix", "~> 1.0"

  spec.add_development_dependency "rspec", "~> 3.0"
end
