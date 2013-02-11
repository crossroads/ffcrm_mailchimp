FactoryGirl.define do
  sequence :klass_name do |x|
    ["Contact", "Account", "Opportunity", "Lead", "Campaign"].sample
  end

  sequence(:field_position) {|x| x }

  sequence :field_label do |x|
    Faker::Internet.user_name + x.to_s
  end

  factory :field_group do
    klass_name          { FactoryGirl.generate(:klass_name) }
    label               { FactoryGirl.generate(:field_label) }
    tag                 
  end


  factory :field do
    type                "Field"
    field_group         { FactoryGirl.create(:field_group) }
    position            { FactoryGirl.generate(:field_position) }
    label               { FactoryGirl.generate(:field_label) }
    name                { |f| f.label.downcase.gsub(/[^a-z0-9]+/, '_') }
    as                  "string"
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }
  end


  factory :custom_field do
    type    "CustomField"
  end
end