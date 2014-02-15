require 'ffcrm_mailchimp/webhook_params'

describe FfcrmMailchimp::WebhookParams do

  let(:email)      { "test@example.com" }
  let(:new_email)  { "new_test@example.com" }
  let(:old_email)  { "old_test@example.com" }
  let(:list_id)    { "3e26bc072d" }
  let(:first_name) { "Bob" }
  let(:last_name)  { "Lee" }
  let(:interests)  { "group1, group2" }
  let(:group_id)   { "5641" }
  let(:groupings)  { {"0"=> { "id" => group_id, "name" => "Groups", "groups" => interests } } }
  let(:data)       { { email: email, new_email: new_email, old_email: old_email, list_id: list_id,
                       merges: { EMAIL: email, FNAME: first_name, LNAME: last_name,
                                 INTERESTS: interests, GROUPINGS: groupings } } }
  let(:hook)       { FfcrmMailchimp::WebhookParams.new( data: data ) }

  context "email" do
    it { expect( hook.email ).to eql( email ) }
  end

  context "merges_email" do
    it { expect( hook.merges_email ).to eql( email ) }
  end

  context "old_email" do
    it { expect( hook.old_email ).to eql( old_email ) }
  end

  context "new_email" do
    it { expect( hook.new_email ).to eql( new_email ) }
  end

  context "list_id" do
    it { expect( hook.list_id ).to eql( list_id ) }
  end

  context "interests" do
    it { expect( hook.interests ).to eql( interests ) }
  end

  context "groupings" do
    it { expect( hook.groupings ).to eql( groupings ) }
  end

  context "first_name" do
    it { expect( hook.first_name ).to eql( first_name ) }
  end

  context "last_name" do
    it { expect( hook.last_name ).to eql( last_name ) }
  end

  context "attributes" do
    it { expect( hook.attributes ).to include( "5641_group1" ) }
    it { expect( hook.attributes ).to include( "5641_group2" ) }
    it { expect( hook.attributes ).to include( "list_#{list_id}" ) }
    it { expect( hook.attributes ).to include( "source_webhook" ) }
  end

end
