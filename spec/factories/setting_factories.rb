FactoryGirl.define do
  factory :setting do
    name                "foo"
    value               nil
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }

    factory :ffcrm_mailchimp do
      name "ffcrm_mailchimp"
      value {{webhook_key:"aswkgjfikdl"}}
    end
  end
end