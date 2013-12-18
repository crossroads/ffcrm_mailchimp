require 'spec_helper'
describe FfcrmMailchimp::MailchimpEndpoint do

  let(:data){ FactoryGirl.build :data}
  let(:response){ FactoryGirl.build :response}
  let(:field_data){ { custom_field: ["group1", "group2"] } }

  describe "Mailchimp" do

    describe "User Profile" do

      before(:each) do
        Contact.delete_all
        @mod = generate_response("profile")
      end

      context "authenticate" do
        it "should authenticate request and return true for correct api_key" do
          result = @mod.authenticate
          result.should_not be_blank
          result.should eq true
        end

        it "should authenticate request and return false for incorrect api_key" do
          result = @mod.authenticate
          result.should_not be_blank
          result.should eq true
        end
      end

      it "should update profile of user" do
        FactoryGirl.create(:contact, email: "test@example.com")
        @mod.profile_update
        record = Contact.find_by_email("test@example.com")
        record.first_name.should eq "Bob"
        record.last_name.should eq "Lee"
      end
    end

    describe "Subscribe new user" do

      before(:each) do
        @mod = generate_response("subscribe")
      end

      it "should create new user" do
        record = Contact.find_by_email(response[:data][:email])
        @mod.authenticate
        contact = Contact.find_by_email(response[:data][:email])
        record.should be_blank
        contact.should_not be_blank
        contact.email.should eq response[:data][:email]
      end

      it "should not create duplicate record if user exists" do
        record = [ FactoryGirl.create(:contact, email: "ryan@example.com") ]
        @mod.authenticate
        contact = Contact.where(email: response[:data][:email])
        record.count.should eq 1
        contact.count.should eq 1
      end
    end

    describe "User Email" do

      before(:each) do
        Contact.delete_all
        @mod = generate_response("upemail")
        FactoryGirl.create(:contact, email: "test@example.com", first_name: "Stanley")
      end

      it "should update user email if email is updated " do
        @mod.authenticate
        record = Contact.where(email: "new_test@example.com", first_name: "Stanley")
        record.first.email.should eq "new_test@example.com"
      end

      it "should not update user email_id if new email_id already exists" do
        FactoryGirl.create(:contact, email: "new_test@example.com")
        @mod.authenticate
        record = Contact.where(email: "test@example.com")
        record.should_not be_blank
      end
    end

    describe "Unsubscribe User" do

      before(:each) do
        Contact.delete_all
        @mod = generate_response("unsubscribe")
        @mod.stub(:customfield_value).and_return(field_data)
      end

      it "should unsubscribe user and update custom field value" do
        contact = FactoryGirl.create(:contact, email: 'test@example.com',
          custom_field: ["group1", "group2"])
        record = Contact.find_by_email(data[:data][:email])
        @mod.unsubscribe.should be_true
        record.reload.custom_field.should eq "--- []\n"
      end
    end

    describe "Mailchimp List" do

      before(:each) do
        Contact.delete_all
        @mod = generate_response("profile")
        @mod.stub(:customfield_value).and_return(field_data)
      end

      it "should update user list and group detail in custom field" do
        contact = FactoryGirl.create(:contact, email: 'test@example.com',custom_field: ["group1", "group2"])
        @mod.profile_update
        record = Contact.find_by_email(data[:data][:email])
        record.should_not be_blank
        record.custom_field.should be_present
      end
    end

  end

  def generate_response(response_type)
    hash = response_type == "subscribe" ? response.merge({type: response_type}) : data.merge({type: response_type})
    FfcrmMailchimp::Config.any_instance.stub_chain('api_key').
      and_return("1f443fda6e6fab633b8509asdsdhga34234-us3")
    param = FfcrmMailchimp::InboundSync.new(hash)
    data = FfcrmMailchimp::MailchimpEndpoint.new(param)
    return data
  end
end