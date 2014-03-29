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
        sync.stub(:subscribed_email).and_return(email)
        sync.stub(:mailchimp_list_field_names).and_return( ['custom_field'] )
        sync.stub(:list_id_from_column).and_return( list_id )
        subscription.stub(:wants_to_subscribe?).and_return(true)
        FfcrmMailchimp::ListSubscription.stub(:new).and_return(subscription)
      end
      it {
        expect(sync).to receive(:apply_mailchimp_subscription).with(subscription, list_id)
        sync.subscribe
      }
    end

    context "when unsubscribing a contact from the mailchimp list" do
      before {
        sync.stub(:subscribed_email).and_return(email)
        sync.stub(:mailchimp_list_field_names).and_return( ['custom_field'] )
        subscription.stub(:wants_to_subscribe?).and_return(false)
        FfcrmMailchimp::ListSubscription.stub(:new).and_return(subscription)
        sync.stub(:list_id_from_column).with('custom_field').and_return(list_id)
      }
      it {
        expect(sync).to receive(:unsubscribe_from_mailchimp_list).with(list_id)
        sync.subscribe
      }
    end

    context "when no changes have been detected" do
      before {
        sync.stub(:subscribed_email).and_return(email)
        sync.stub(:mailchimp_list_field_names).and_return( [] )
      }
      it {
        expect(sync).to_not receive(:unsubscribe_from_mailchimp_list)
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
        sync.should_receive(:unsubscribe_from_mailchimp_list).with(list_id, email)
        sync.unsubscribe(email)
      end
    end

    context "when subscribed_email is blank" do
      it "should not unsubscribe the user from the mailchimp list" do
        sync.stub(:subscribed_email).and_return(nil)
        sync.should_not_receive(:unsubscribe_from_mailchimp_list)
        sync.unsubscribe('')
      end
    end

  end

  describe ".is_subscribed_mailchimp_user?" do

    before { sync.stub(:subscribed_email).and_return(email) }

    context "when subscribed_email present" do

      context "when user is subscribed" do
        before {
          Gibbon::API.any_instance.stub_chain('lists.member_info').and_return( {"error_count" => 0, "data" => [{ "status" => 'subscribed'}] })
        }
        it { expect( sync.send(:is_subscribed_mailchimp_user?, '1234') ).to eql(true) }
      end

      context "when user is not subscribed" do
        before {
          Gibbon::API.any_instance.stub_chain('lists.member_info').and_return({ "error_count" => 1 })
        }
        it { expect( sync.send(:is_subscribed_mailchimp_user?, '1234') ).to eql(false) }
      end

      context "when user is not subscribed but was previously" do
        before {
          Gibbon::API.any_instance.stub_chain('lists.member_info').and_return({"error_count" => 0, "data" => [{ "status" => 'unsubscribed'}]})
        }
        it { expect( sync.send(:is_subscribed_mailchimp_user?, '1234') ).to eql(false) }
      end

    end

  end

  describe "apply_mailchimp_subscription" do

    let(:api_call) { double }
    before { sync.stub(:subscribed_email).and_return(email) }

    it "should subscribe user to mailchimp list with particular interest groups" do
      sync.stub(:is_subscribed_mailchimp_user?).with(list_id).and_return(false)
      Gibbon::API.any_instance.stub_chain('lists').and_return(api_call)
      api_call.should_receive('subscribe') do |args|
        expect( args[:id] ).to eql( list_id )
        expect( args[:email] ).to eql( {email: email} )
        expect( args[:merge_vars][:FNAME] ).to eql( contact.first_name )
        expect( args[:merge_vars][:LNAME] ).to eql( contact.last_name )
        expect( args[:merge_vars][:groupings].first['id'] ).to eql( group_id )
        expect( args[:merge_vars][:groupings].first['groups'] ).to eql( groups )
        expect( args[:merge_vars].has_key?('new-email') ).to be_false
        expect( args[:double_optin] ).to eql( false )
      end
      sync.send(:apply_mailchimp_subscription, subscription, list_id)
    end

    it "should update user subscription if user is already subscribed to the list" do
      sync.stub(:is_subscribed_mailchimp_user?).with(list_id).and_return(true)
      Gibbon::API.any_instance.stub_chain('lists').and_return(api_call)
      api_call.should_receive('subscribe') do |args|
        expect( args[:update_existing] ).to eql( "true" )
        expect( args[:merge_vars].has_key?('new-email') ).to be_false
      end
      sync.send(:apply_mailchimp_subscription, subscription, list_id)
    end

    it "should update email of subscription if contact email is updated" do
      new_email = "test-#{contact.email}"
      contact.email = new_email
      sync.stub(:is_subscribed_mailchimp_user?).with(list_id).and_return(true)
      Gibbon::API.any_instance.stub_chain('lists').and_return(api_call)
      api_call.should_receive('subscribe') do |args|
        expect( args[:update_existing] ).to eql( "true" )
        expect( args[:merge_vars]['new-email'] ).to eql( new_email )
      end
      sync.send(:apply_mailchimp_subscription, subscription, list_id)
    end

    it "should do nothing if new_email is blank but subscribed_email is not" do
      contact.stub(:email).and_return(nil)
      Gibbon::API.any_instance.stub_chain('lists').and_return(api_call)
      api_call.should_not_receive('subscribe')
      sync.send(:apply_mailchimp_subscription, subscription, list_id)
    end

  end

  describe "unsubscribe_from_mailchimp_list" do

    before { sync.stub(:subscribed_email).and_return(email) }

    it "should unsubscribe existing contact from mailchimp list" do
      sync.stub(:is_subscribed_mailchimp_user?).with(list_id, email).and_return(true)
      Gibbon::API.any_instance.stub_chain('lists').and_return(mock_api_call)
      mock_api_call.should_receive('unsubscribe') do |args|
        expect( args[:id] ).to eql( list_id )
        expect( args[:email][:email] ).to eql( email )
        expect( args[:email][:delete_member] ).to eql( true )
        expect( args[:email][:send_notify] ).to eql( false )
      end
      sync.send(:unsubscribe_from_mailchimp_list, list_id)
    end

    it "should not unsubscribe a contact that isn't subscribed" do
      sync.stub(:is_subscribed_mailchimp_user?).with(list_id, email).and_return(false)
      Gibbon::API.any_instance.stub_chain('lists').and_return(mock_api_call)
      mock_api_call.should_not_receive('unsubscribe')
      sync.send(:unsubscribe_from_mailchimp_list, list_id)
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

  def setup_custom_field_record
    field_group = FactoryGirl.create(:field_group, klass_name: "Contact")
    list = { list_id: "3e26bc072d" }.with_indifferent_access
    field = FactoryGirl.create(:field, field_group_id: field_group.id, type: "CustomFieldMailchimpList",
      label: "custom_field", name: "custom_field", as: "mailchimp_list", settings: list)
  end

  def teardown_custom_field_record
    FieldGroup.delete_all
    CustomFieldMailchimpList.delete_all
  end

end
