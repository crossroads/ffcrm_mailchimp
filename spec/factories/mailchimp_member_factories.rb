require 'ffaker'
require 'ffcrm_mailchimp/member'

FactoryGirl.define do

  factory :mailchimp_member, class: FfcrmMailchimp::Member do
    email_address   { Faker::Internet.email }
    status          { "subscribed" }
    list_id         { '12345' }
    merge_fields    { {"FIRST_NAME" => Faker::Name.first_name, "LAST_NAME" => Faker::Name.last_name} }
    interests       { {"70b7107c8a" => true, "7c1719c788" => false, "8d856390f6" => true} }
    initialize_with { attributes }
  end

end
