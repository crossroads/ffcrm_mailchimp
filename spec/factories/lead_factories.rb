FactoryGirl.define do
  factory :lead do
    user                
    campaign            
    assigned_to         nil
    first_name          { Faker::Name.first_name }
    last_name           { Faker::Name.last_name }
    access              "Public"
    company             { Faker::Company.name }
    title               { FactoryGirl.generate(:title) }
    source              { %w(campaign cold_call conference online referral self web word_of_mouth other).sample }
    status              { %w(new contacted converted rejected).sample }
    rating              1
    referred_by         { Faker::Name.name }
    do_not_call         false
    blog                { FactoryGirl.generate(:website) }
    linkedin            { FactoryGirl.generate(:website) }
    facebook            { FactoryGirl.generate(:website) }
    twitter             { FactoryGirl.generate(:website) }
    email               { Faker::Internet.email }
    alt_email           { Faker::Internet.email }
    phone               { Faker::PhoneNumber.phone_number }
    mobile              { Faker::PhoneNumber.phone_number }
    background_info     { Faker::Lorem.paragraph[0,255] }
    deleted_at          nil
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }
  end
end