require 'spec_helper'
describe FfcrmMailchimp::MailchimpEndpoint do

  let(:data){ FactoryGirl.build :data}

  describe "Mailchimp" do

    describe "User Profile" do

      before(:each) do
        User.delete_all
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
        FactoryGirl.create(:user, email: "test@example.com")
        @mod.authenticate
        record = User.find_by_email("test@example.com")
        record.first_name.should eq "Bob"
        record.last_name.should eq "Lee"
      end
    end

    describe "User Email" do

      before(:each) do
        User.delete_all
        hash = data.merge({type: "upemail"})
        FfcrmMailchimp::Config.any_instance.stub_chain('api_key').
          and_return("1f443fda6e6fab633b8509asdsdhga34234-us3")
        param = FfcrmMailchimp::InboundSync.new(hash)
        @mod = FfcrmMailchimp::MailchimpEndpoint.new(param)
      end

      it "should update user email if updated" do
        FactoryGirl.create(:user, email: "test@example.com", first_name: "Stanley")
        @mod.authenticate
        record = User.where(email: "new_test@example.com", first_name: "Stanley")
        record.first.email.should eq "new_test@example.com"
      end
    end

    describe "Subscribe new user" do

      before(:each) do
        hash = data.merge({type: "subscribe"})
        FfcrmMailchimp::Config.any_instance.stub_chain('api_key').
          and_return("1f443fda6e6fab633b8509asdsdhga34234-us3")
        param = FfcrmMailchimp::InboundSync.new(hash)
        @mod = FfcrmMailchimp::MailchimpEndpoint.new(param)
      end

      it "should create new user" do
      end
    end
  end
end