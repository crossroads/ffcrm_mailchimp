source 'https://rubygems.org'

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
gemspec

gem 'ffcrm_endpoint', git: 'https://github.com/fatfreecrm/ffcrm_endpoint', branch: 'rails4'

group :development, :test do
  gem 'factory_girl_rails'
  gem 'byebug' unless ENV['CI']
end
