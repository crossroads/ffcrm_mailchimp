require 'spec_helper'

describe FfcrmMailchimp::WebhookParams do

  let(:webhook_data)  { FactoryGirl.build(:mc_webhook)[:data] }
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
    it { expect( webhook.first_name ).to eql( webhook_data['merges']['FNAME'] ) }
  end

  context "last_name" do
    it { expect( webhook.last_name ).to eql( webhook_data['merges']['LNAME'] ) }
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

end
