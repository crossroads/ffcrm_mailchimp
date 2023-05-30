require 'ffaker'

FactoryBot.define do

  # FfcrmMailchimp::Changes.new(record)
  factory :changes, class: FfcrmMailchimp::Changes do
    initialize_with { attributes }
  end

end
