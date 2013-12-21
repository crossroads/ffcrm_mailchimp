require 'spec_helper'

describe FfcrmMailchimp::OutboundSync do

  let(:params){ {email: 'test@example.com', custom_field: [{"list_id"=> "3e26bc072d",
    "groupings" => [{"group_id" => "1525", "groups"=>["group1","group2"]}], "source"=> "ffcrm"}]} }

  describe ".is_subscribed_mailchimp_user" do

    before(:each) do
      Contact.delete_all
      FfcrmMailchimp::OutboundSync.any_instance.stub(:subscribe_to_mailchimp_group).
        with("3e26bc072d", "test@example.com", "1525", ["group1", "group2"]).and_return(nil)
    end

    it "should check if user is subscribed mailchimp user" do
      generate_custom_field_record
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:is_subscribed_mailchimp_user).
        with("3e26bc072d", "test@example.com", "subscribe")
      FactoryGirl.create(:contact, params)
    end

    it "should check if user already exist on mailchimp while unsubscribing" do
      contact = FactoryGirl.create(:contact, params)
      generate_custom_field_record
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:is_subscribed_mailchimp_user).
        with("3e26bc072d", "test@example.com", "unsubscribe")
      contact.update_attributes(custom_field: [{"source"=> "ffcrm"}])
    end
  end

  describe ".subscribe_to_mailchimp_group" do

    before(:each) do
      Contact.delete_all
    end

    it "should subscribe user to mailchimp group" do
      generate_custom_field_record
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:is_subscribed_mailchimp_user).
        with("3e26bc072d", "test@example.com", "subscribe").and_return(false)
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:subscribe_to_mailchimp_group).
        with("3e26bc072d", "test@example.com", "1525", ["group1", "group2"])
      FactoryGirl.create(:contact, params)
    end
  end

  describe ".subscribe_to_mailchimp_list" do

    before(:each) do
      Contact.delete_all
    end

    it "should subscribe user to mailchimp list" do
      generate_custom_field_record
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:is_subscribed_mailchimp_user).
        with("3e26bc072d", "test@example.com", "subscribe").and_return(false)
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:subscribe_to_mailchimp_group).
        with("3e26bc072d", "test@example.com", nil, nil)
      FactoryGirl.create(:contact, email: 'test@example.com',
        custom_field: [{"list_id"=> "3e26bc072d", "source"=> "ffcrm"}])
    end
  end

  describe ".unsubscribe_from_mailchimp_group" do

    before(:each) do
      Contact.delete_all
      @contact = FactoryGirl.create(:contact, params)
    end

    it "should unsubscribe user from mailchimp group" do
      generate_custom_field_record
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:is_subscribed_mailchimp_user).
        with("3e26bc072d", "test@example.com", "subscribe").and_return(true)
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:update_subscription_to_mailchimp).
        with("3e26bc072d", "test@example.com", nil, nil)
      @contact.update_attributes(:custom_field => [{"list_id"=> "3e26bc072d", "source"=> "ffcrm"}])
    end
  end

  describe ".unsubscribe_from_mailchimp_list" do

    before(:each) do
      Contact.delete_all
      @contact = FactoryGirl.create(:contact, params)
    end

    it "should unsubscribe user from mailchimp list" do
      generate_custom_field_record
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:is_subscribed_mailchimp_user).
        with("3e26bc072d", "test@example.com", "unsubscribe").and_return(true)
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:unsubscribe_from_mailchimp_group).
        with("3e26bc072d", "test@example.com")
      @contact.update_attributes(:custom_field => [{"source"=> "ffcrm"}])
    end
  end

  describe ".update_profile_in_mailchimp" do

    before(:each) do
      Contact.delete_all
      @contact = FactoryGirl.create(:contact, params)
    end

    it "should update user details in mailchimp" do
      generate_custom_field_record
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:is_subscribed_mailchimp_user).
        with("3e26bc072d", "test@example.com", "subscribe").and_return(true)
      FfcrmMailchimp::OutboundSync.any_instance.should_receive(:update_subscription_to_mailchimp).
        with("3e26bc072d", "test@example.com", "1525", ["group1"])
      @contact.update_attributes(:custom_field => [{"list_id"=> "3e26bc072d",
        "groupings" => [{"group_id" => "1525", "groups"=>["group1"]}], "source"=> "ffcrm"}])
    end
  end

  def generate_custom_field_record
    field_group = FactoryGirl.create(:field_group, klass_name: "Contact")
    list = ActiveSupport::HashWithIndifferentAccess.new
    list[:list_id] = "3e26bc072d"
    field = FactoryGirl.create(:field, field_group_id: field_group.id, type: "CustomFieldMailchimpList",
      label: "custom_field", name: "custom_field", as: "mailchimp_list", settings: list)
  end
end