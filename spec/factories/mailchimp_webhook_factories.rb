FactoryGirl.define do

  factory :mc_webhook, class: Hash do
    data {{ 'email' => "test@example.com",
            'merges' => {
              'EMAIL' => "test@example.com",
              'FIRST_NAME' => "Bob",
              'LAST_NAME' => "Lee",
              'INTERESTS' => "group1, group2",
              'GROUPINGS' => {
                "0"=>
                  {"id"=>"5641",
                   "name"=>"Group One",
                   "groups"=>"Option 1, Option 2"
                  },
                "1"=>
                  {"id"=>"8669",
                   "name"=>"Group Two",
                   "groups"=>"Option 3, Option 4"
                  }
              }
            },
            'new_email' => "new_test@example.com",
            'old_email' => "test@example.com",
            'list_id' => "3e26bc072d"
         }}
    type "subscribe"
    fired_at { Time.now }
    controller "ffcrm_endpoint/endpoints"
    action     "consume"
    klass_name  "mailchimp_endpoint"
    api_key ''
    initialize_with { attributes }
  end

end
