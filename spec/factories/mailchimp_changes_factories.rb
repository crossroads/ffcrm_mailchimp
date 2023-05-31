require 'ffaker'
require 'ffcrm_mailchimp/changes'

FactoryBot.define do

  # FfcrmMailchimp::Changes.new(record)
  factory :changes, class: FfcrmMailchimp::Changes do
    initialize_with { attributes }
  end

end
