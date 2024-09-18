# frozen_string_literal: true

require_relative "lib/ar_virtual_field/version"

Gem::Specification.new do |spec|
  spec.name = "ar_virtual_field"
  spec.version = ArVirtualField::VERSION
  spec.authors = ["Pavel Egorov"]
  spec.email = ["moonmeander47@ya.ru"]

  spec.summary = "Provide an easy mechanism to define virtual fields within an ActiveRecord model"
  spec.description = "Adds .virtual_field method to make it easy to define virtual fields"
  spec.homepage = "https://github.com/emfy0/ar_virtual_field"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency "activerecord", ">= 6.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/emfy0/ar_virtual_field"

  spec.files = Dir["{lib}/**/*", "LICENSE.txt", "README.md"]

  spec.require_paths = ["lib"]

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec"
end
