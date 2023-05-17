require 'ostruct'
require 'ffaker'

FactoryGirl.define do

  # {"id"=>8661,
  #  "title"=>"Group One",
  #  "groups"=>
  #    [{"id"=>"1", "name"=>"Option 1"},
  #     {"id"=>"2", "name"=>"Option 2"}]}
  #

  factory :mailchimp_group, class: OpenStruct do
    id              { rand(1000) }
    title           { Faker::Name.first_name }
    list_id         { rand(1000) }
    groups          { [ build(:interest_grouping), build(:interest_grouping) ] }
    initialize_with { attributes }
  end

  factory :interest_grouping, class: Hash do
    id              { rand(1000) }
    name            { Faker::Lorem.sentence(1) }
    initialize_with { attributes }
  end

end
