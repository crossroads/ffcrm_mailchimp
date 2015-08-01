require 'ffaker'
require 'ffcrm_mailchimp/member'

FactoryGirl.define do

  factory :mailchimp_member, class: FfcrmMailchimp::Member do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name  { FFaker::Name.last_name }
    list_id { '12345' }
    subscribed_groups { {'Group One' => "Option 1, Option 2", "Group Two" => "Option 3" } }
    last_changed { DateTime.now }
    phone { FFaker::PhoneNumber.phone_number }
    initialize_with { attributes }
  end

end
