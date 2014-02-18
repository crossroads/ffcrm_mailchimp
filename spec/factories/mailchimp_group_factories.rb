FactoryGirl.define do
  factory :interest_groupings, class: Gibbon::APICategory do
    bit { rand(10) }
    name Faker::Lorem.sentence(1)
    display_order { rand(10) }
    subscribers { Faker::Name.first_name }
    initialize_with { attributes }
  end
end