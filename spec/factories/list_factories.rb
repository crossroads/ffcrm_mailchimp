FactoryGirl.define do
  factory :list, class: Gibbon::APICategory do
    id "test1234"
    web_id { rand(10) }
    name Faker::Lorem.sentence(1)
    date_created  {FactoryGirl.generate(:time)}
    email_type_option false
    use_awesomebar true
    default_from_name Faker::Lorem.sentence(1)
    default_from_email Faker::Internet.email
    default_subject ""
    default_language "en"
    list_rating 0
    subscribe_url_short {FactoryGirl.generate(:website)}
    subscribe_url_long {FactoryGirl.generate(:website)}
    beamer_address Faker::Internet.email
    visibility "pub"
    initialize_with { attributes }
  end
end