source 'https://rubygems.org'

# Declare your gem's dependencies in ffcrm_mailchimp.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"
gem 'fat_free_crm', :github => 'fatfreecrm/fat_free_crm'
gem 'gibbon'

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

group :development do
  unless ENV['CI']
    gem 'byebug'
    gem 'guard-rspec', require: false
  end
end
