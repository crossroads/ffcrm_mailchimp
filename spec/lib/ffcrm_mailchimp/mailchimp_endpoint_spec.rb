require 'spec_helper'
describe FfcrmMailchimp::MailchimpEndpoint do

  let(:data){ FactoryGirl.build :data}
  let(:response){ FactoryGirl.build :response}

  describe "Mailchimp" do

    describe "User Profile" do

      before(:each) do
        Contact.delete_all
        hash = data.merge({type: "profile"})
        FfcrmMailchimp::Config.any_instance.stub_chain('api_key').
          and_return("1f443fda6e6fab633b8509asdsdhga34234-us3")
        param = FfcrmMailchimp::InboundSync.new(hash)
        @mod = FfcrmMailchimp::MailchimpEndpoint.new(param)
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
        @mod.authenticate
        record = Contact.find_by_email("test@example.com")
        record.first_name.should eq "Bob"
        record.last_name.should eq "Lee"
      end
    end

    describe "User Email" do

      before(:each) do
        Contact.delete_all
        hash = data.merge({type: "upemail"})
        FfcrmMailchimp::Config.any_instance.stub_chain('api_key').
          and_return("1f443fda6e6fab633b8509asdsdhga34234-us3")
        param = FfcrmMailchimp::InboundSync.new(hash)
        @mod = FfcrmMailchimp::MailchimpEndpoint.new(param)
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

    describe "Subscribe new user" do

      before(:each) do
        hash = response.merge({type: "subscribe"})
        FfcrmMailchimp::Config.any_instance.stub_chain('api_key').
          and_return("1f443fda6e6fab633b8509asdsdhga34234-us3")
        param = FfcrmMailchimp::InboundSync.new(hash)
        @mod = FfcrmMailchimp::MailchimpEndpoint.new(param)
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
  end
end