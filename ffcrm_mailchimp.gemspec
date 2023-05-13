$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ffcrm_mailchimp/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ffcrm_mailchimp"
  s.version     = FfcrmMailchimp::VERSION
  s.authors     = ["Steve Kenworthy"]
  s.email       = ["steveyken@gmail.com"]
  s.homepage    = "http://www.fatfreecrm.com"
  s.summary     = "A Fat Free CRM plugin to enable mailchimp functionality."
  s.description = "Enables Fat Free CRM contact data to be synchronised to and from a mailchimp account."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.11"
  s.add_dependency "fat_free_crm"
  s.add_dependency "ffcrm_endpoint"
  s.add_dependency "gibbon", "~>1"
  s.add_dependency "delayed_job_active_record"
  s.add_development_dependency "pg"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'haml', '~>3'
  s.add_development_dependency 'sass', '~>3.3.3'
end
