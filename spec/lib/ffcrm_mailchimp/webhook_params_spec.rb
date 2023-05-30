require 'rails_helper'
require 'ffcrm_mailchimp/webhook_params'

describe 'FfcrmMailchimp::WebhookParams' do

  let(:webhook_data)  { FactoryBot.build(:mailchimp_webhook)[:data] }
  let(:webhook)       { FfcrmMailchimp::WebhookParams.new( data: webhook_data ) }

  context "email" do
    it { expect( webhook.email ).to eql( webhook_data['email'] ) }
  end

  context "merges_email" do
    it { expect( webhook.merges_email ).to eql( webhook_data['merges']['EMAIL'] ) }
  end

  context "old_email" do
    it { expect( webhook.old_email ).to eql( webhook_data['old_email'] ) }
  end

  context "new_email" do
    it { expect( webhook.new_email ).to eql( webhook_data['new_email'] ) }
  end

  context "list_id" do
    it { expect( webhook.list_id ).to eql( webhook_data['list_id'] ) }
  end

  context "groupings" do
    it { expect( webhook.groupings ).to eql( webhook_data['merges']['GROUPINGS'] ) }
  end

  context "first_name" do
    it { expect( webhook.first_name ).to eql( webhook_data['merges']['FIRST_NAME'] ) }
  end

  context "last_name" do
    it { expect( webhook.last_name ).to eql( webhook_data['merges']['LAST_NAME'] ) }
  end

  context "to_list_subscription" do
    subject { webhook.to_list_subscription }
    it { expect( subject.list_id ).to eql( webhook_data['list_id'] ) }
    it { expect( subject.source ).to eql( 'webhook' ) }
    it { expect( subject.groupings.first['id'] ).to eql( webhook_data['merges']['GROUPINGS']['0']['id'] ) }
    it { expect( subject.groupings.first['groups'] ).to eql( webhook_data['merges']['GROUPINGS']['0']['groups'].split(', ') ) }
    it { expect( subject.groupings.last['id'] ).to eql( webhook_data['merges']['GROUPINGS']['1']['id'] ) }
    it { expect( subject.groupings.last['groups'] ).to eql( webhook_data['merges']['GROUPINGS']['1']['groups'].split(', ') ) }
  end

########################################

  let(:list_id) { "4a1df096f3" }
  let(:interest_groupings) { 
    [ {"list_id" => list_id, "id" => "34b9452245", "title" => "Interest group 1", 
       "groups"=>[ {"id"=>"70b7107c8a", "name"=>"Option 1"}, {"id"=>"7c1719c788", "name"=>"Option 2"}, {"id"=>"8d856390f6", "name"=>"Option 3"}]
      }
    ]
  }
  let(:api_member_hash) {
    { "email_address" => "test@example.com",
      "list_id" => list_id,
      "status" => "subscribed",
      "merge_fields" => {"FIRST_NAME" => "First name", "LAST_NAME" => "Last name", "CONSENT" => "Yes"},
      "interests" => {"70b7107c8a" => true, "7c1719c788" => false, "8d856390f6" => true}
    }
  }

  before do
    allow(FfcrmMailchimp::Api).to receive("interest_groupings").with(list_id).and_return(interest_groupings)
  end

  context "new_from_api" do
    subject { FfcrmMailchimp::WebhookParams.new_from_api(api_member_hash) }
    it { expect( subject[:data]["email"] ).to eql( 'test@example.com' ) }
    it { expect( subject[:data]["consent"] ).to eql( 'Yes' ) }
    it { expect( subject[:data]['list_id'] ).to eql( list_id ) }
    it { expect( subject[:data]["merges"]['FIRST_NAME'] ).to eql( 'First name' ) }
    it { expect( subject[:data]["merges"]['LAST_NAME'] ).to eql( 'Last name' ) }
    it { expect( subject[:data]["merges"]['EMAIL'] ).to eql( 'test@example.com' ) }
    it { expect( subject[:data]["merges"]['GROUPINGS']["0"]["id"] ).to eql( "34b9452245" ) }
    it { expect( subject[:data]["merges"]['GROUPINGS']["0"]["name"] ).to eql( "Interest group 1" ) }
    it { expect( subject[:data]["merges"]['GROUPINGS']["0"]["groups"] ).to eql( "Option 1, Option 3" ) }
  end

end
