$:.push File.expand_path("../lib", __FILE__)

require "ffcrm_mailchimp/version"

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

  s.add_dependency "rails"
  s.add_dependency "ffcrm_endpoint"
  s.add_dependency "gibbon"
  s.add_dependency "delayed_job_active_record"
  s.add_development_dependency "fat_free_crm"
  s.add_development_dependency 'factory_bot_rails'
  s.add_development_dependency "pg"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency "ransack_ui"
end
