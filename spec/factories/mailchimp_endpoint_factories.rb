FactoryGirl.define do

  factory :data, class:Hash do
    data {{ email: "test@example.com",
            merges: {
              EMAIL: "test@example.com",
              FNAME: "Bob",
              LNAME: "Lee"
            },
            new_email: "new_test@example.com",
            old_email: "test@example.com"
         }}
    controller "ffcrm_endpoint/endpoints"
    action     "consume"
    klass_name  "mailchimp_endpoint"
    api_key "1f443fda6e6fab633b8509asdsdhga34234-us3"
    initialize_with { attributes }
  end
end