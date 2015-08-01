require 'ostruct'
require 'ffaker'

FactoryGirl.define do

  # {"id"=>8661,
  #  "name"=>"Group One",
  #  "form_field"=>"checkboxes",
  #  "display_order"=>"0",
  #  "groups"=>
  #    [{"bit"=>"1", "name"=>"Option 1", "display_order"=>"1", "subscribers"=>nil},
  #     {"bit"=>"2", "name"=>"Option 2", "display_order"=>"2", "subscribers"=>nil}]}
  #

  factory :mailchimp_group, class: OpenStruct do
    id              { rand(1000) }
    name            { FFaker::Name.first_name }
    list_id         { rand(1000) }
    form_field      { 'checkboxes' }
    display_order   { rand(100) }
    groups          { [ build(:interest_grouping), build(:interest_grouping) ] }
    initialize_with { attributes }
  end

  factory :interest_grouping, class: Hash do
    bit             { rand(100) }
    name            { FFaker::Lorem.sentence(1) }
    display_order   { rand(100) }
    subscribers     { FFaker::Name.first_name }
    initialize_with { attributes }
  end

end
