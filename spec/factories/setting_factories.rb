FactoryGirl.define do
  factory :setting do
    name                "foo"
    value               nil
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }

    factory :ffcrm_mailchimp do
      name "ffcrm_mailchimp"
      value {{api_key:"1f443fda6e6fab633b8509asdsdhga34234-us3"}}
    end
  end
end