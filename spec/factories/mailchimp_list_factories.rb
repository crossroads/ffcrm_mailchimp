FactoryBot.define do
  factory :mailchimp_list, class: FfcrmMailchimp::List do
    id { "test1234" }
    web_id { rand(10) }
    name { FFaker::Lorem.sentence(1) }
    date_created  {FactoryBot.generate(:time)}
    email_type_option { false }
    use_awesomebar { true }
    default_from_name { FFaker::Lorem.sentence(1) }
    default_from_email { FFaker::Internet.email }
    default_subject { "" }
    default_language { "en" }
    list_rating { 0 }
    subscribe_url_short { FactoryBot.generate(:website) }
    subscribe_url_long { FactoryBot.generate(:website) }
    beamer_address { FFaker::Internet.email }
    visibility { "pub" }
    initialize_with { attributes }
  end
end
