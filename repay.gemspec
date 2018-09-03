$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "repay/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "repay-rest-client-ruby"
  s.version     = Repay::VERSION
  s.authors     = ["jared"]
  s.email       = ["jaredables@gmail.com"]
  s.homepage    = "https://github.com/jarblz/repay_api"
  s.summary     = "Repay API Ruby Abstraction"
  s.description = "This is an abstraction of various requests needed to use the repay API"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 5.2"
  s.add_dependency 'rest-client'
  s.add_dependency 'vcr'

  s.add_development_dependency "sqlite3"
end
