require 'spec_helper'
require 'gibbon'

describe FfcrmMailchimp::OutboundSync do

  before(:all) { setup_custom_field_record }
  after(:all)  { teardown_custom_field_record }

  let(:list_id)  { "3e26bc072d" }
  let(:group_id) { "1525" }
  let(:groups)   { ["group1","group2"] }
  let(:email)    { "test@example.com" }
  let(:groupings) { [{ "id" => group_id, "groups"=> groups }] }
  let(:subscription_params) { {"list_id" => list_id, "groupings" => groupings, "source"=> "ffcrm"} }
  let(:params)  { { email: email, custom_field: subscription_params } }
  let(:contact) { FactoryGirl.build(:contact, params) }
  let(:changes) { FactoryGirl.build(:changes) }
  let(:sync)    { FfcrmMailchimp::OutboundSync.new(contact, changes) }
  let(:subscription) { FfcrmMailchimp::ListSubscription.new( subscription_params ) }
  let(:mock_api_call) { double }

  context "subscribe" do

    context "when subscribing a contact to the mailchimp list" do
      before do
        allow(sync).to receive(:subscribed_email).and_return(email)
        expect(sync).to receive(:mailchimp_list_field_names).and_return( ['custom_field'] )
        expect(sync).to receive(:list_id_from_column).and_return( list_id )
        expect(subscription).to receive(:wants_to_subscribe?).and_return(true)
        expect(FfcrmMailchimp::ListSubscription).to receive(:new).and_return(subscription)
      end
      it {
        expect(sync).to receive(:apply_mailchimp_subscription).with(subscription, list_id)
        sync.subscribe
      }
    end

    context "when unsubscribing a contact from the mailchimp list" do
      before {
        allow(sync).to receive(:subscribed_email).and_return(email)
        allow(sync).to receive(:mailchimp_list_field_names).and_return( ['custom_field'] )
        allow(subscription).to receive(:wants_to_subscribe?).and_return(false)
        allow(FfcrmMailchimp::ListSubscription).to receive(:new).and_return(subscription)
        allow(sync).to receive(:list_id_from_column).with('custom_field').and_return(list_id)
      }
      it {
        expect(FfcrmMailchimp::Api).to receive(:unsubscribe).with(list_id, email)
        sync.subscribe
      }
    end

    context "when no changes have been detected" do
      before {
        allow(sync).to receive(:subscribed_email).and_return(email)
        allow(sync).to receive(:mailchimp_list_field_names).and_return( [] )
      }
      it {
        expect(FfcrmMailchimp::Api).to_not receive(:unsubscribe)
        expect(sync).to_not receive(:apply_mailchimp_subscription)
        sync.subscribe
      }
    end

  end

  describe "unsubscribe" do

    context "when subscribed_email is present" do
      it "should unsubscribe the user from the mailchimp list" do
        sync.stub(:subscribed_email).and_return(email)
        sync.stub(:ffcrm_list_ids).and_return([list_id])
        expect(FfcrmMailchimp::Api).to receive(:unsubscribe).with(list_id, email)
        sync.unsubscribe(email)
      end
    end

    context "when subscribed_email is blank" do
      it "should not unsubscribe the user from the mailchimp list" do
        sync.stub(:subscribed_email).and_return(nil)
        expect(FfcrmMailchimp::Api).to_not receive(:unsubscribe)
        sync.unsubscribe('')
      end
    end

  end

  describe "apply_mailchimp_subscription" do

    before { sync.stub(:subscribed_email).and_return(email) }

    it "should subscribe user to mailchimp list with particular interest groups" do
      expect(FfcrmMailchimp::Api).to receive(:subscribe) do |list_id, subscribed_email, body, groupings|
        expect( list_id ).to eql( list_id )
        expect( subscribed_email ).to eql( email )
        expect( body[:email_address] ).to eql( email )
        expect( body[:merge_fields][:FIRST_NAME] ).to eql( contact.first_name )
        expect( body[:merge_fields][:LAST_NAME] ).to eql( contact.last_name )
        expect( groupings.first['id'] ).to eql( group_id )
        expect( groupings.first['groups'] ).to eql( groups )
      end
      sync.send(:apply_mailchimp_subscription, subscription, list_id)
    end

    it "should update email of subscription if contact email is updated" do
      new_email = "test-#{contact.email}"
      contact.email = new_email
      expect(FfcrmMailchimp::Api).to receive(:subscribe) do |list_id, subscribed_email, body, groupings|
        expect( subscribed_email ).to eql( email )
        expect( body[:email_address] ).to eql( new_email )
      end
      sync.send(:apply_mailchimp_subscription, subscription, list_id)
    end

    it "should do nothing if new_email is blank but subscribed_email is not" do
      contact.stub(:email).and_return(nil)
      expect(FfcrmMailchimp::Api).to_not receive(:subscribe)
      sync.send(:apply_mailchimp_subscription, subscription, list_id)
    end

  end

  describe "ffcrm_list_ids" do
    it "should find all the list_id for the registered mailchimp fields" do
      expect( sync.send(:ffcrm_list_ids) ).to eql( [list_id] )
    end
  end

  describe "list_id_from_column" do
    it "should return the list_id by lookup up the column setting information" do
      expect( sync.send(:list_id_from_column, 'custom_field') ).to eql( list_id )
    end
  end

end
