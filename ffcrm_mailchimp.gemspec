$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ffcrm_mailchimp/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ffcrm_mailchimp"
  s.version     = FfcrmMailchimp::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "http://www.fatfreecrm.com"
  s.summary     = "A Fat Free CRM plugin to enable mailchimp functionality."
  s.description = "TBD - To be described."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.11"
  s.add_dependency "fat_free_crm"

  s.add_development_dependency "pg"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'ffaker'
end
