require 'rails_helper'

describe FfcrmMailchimp::InboundSync do

  before { setup_custom_field_record }
  after { teardown_custom_field_record }

  let(:email)      { "test@example.com" }
  let(:new_email)  { "new_test@example.com" }
  let(:old_email)  { "test@example.com" }
  let(:list_id)    { custom_field_list_id }
  let(:first_name) { "Bob" }
  let(:last_name)  { "Lee" }
  let(:interests) { "group1, group2" }
  let(:group_id)  { "5641" }
  let(:groupings) { {"0"=> { "id" => group_id, "name" => "Groups", "groups" => interests } } }
  let(:cf_groupings) { {"id" => group_id, "groups" => interests.split(', ') } }
  let(:cf_name) { 'custom_field' } # this is hardcoded into db/schema.rb

  let(:data) { { email: email, new_email: new_email, old_email: old_email, list_id: list_id,
                 merges: { EMAIL: email, FIRST_NAME: first_name, LAST_NAME: last_name,
                           INTERESTS: interests, GROUPINGS: groupings }
             } }

  let(:params)  { FactoryBot.build(:mailchimp_webhook, data: data) }
  let(:sync)    { FfcrmMailchimp::InboundSync.new( params ) }
  let(:contact) { FactoryBot.build(:contact) }

  describe "process" do

    before { allow(sync).to receive(:custom_field).and_return( double(CustomField) ) }

    context "when type is 'subscribe'" do
      let(:params) { FactoryBot.build(:mailchimp_webhook, type: 'subscribe') }
      it { expect( sync ).to receive(:subscribe)
           sync.process }
    end

    context "when type is 'profile'" do
      let(:params) { FactoryBot.build(:mailchimp_webhook, type: 'profile') }
      it { expect( sync ).to receive(:profile_update)
           sync.process }
    end

    context "when type is 'upemail'" do
      let(:params) { FactoryBot.build(:mailchimp_webhook, type: 'upemail') }
      it { expect( sync ).to receive(:email_changed)
           sync.process }
    end

    context "when type is 'unsubscribe'" do
      let(:params) { FactoryBot.build(:mailchimp_webhook, type: 'unsubscribe') }
      it { expect( sync ).to receive(:unsubscribe)
           sync.process }
    end

    context "when no custom field exists for this list" do

      it "should do nothing" do
        expect(sync).to receive(:custom_field).and_return( nil )
        expect(sync).not_to receive(:subscribe)
        expect(sync).not_to receive(:profile_update)
        expect(sync).not_to receive(:email_changed)
        expect(sync).not_to receive(:unsubscribe)
        sync.process
      end

    end


  end

  describe "subscribe" do

    let(:params)  { FactoryBot.build(:mailchimp_webhook, type: 'subscribe', data: data) }

    context "when user doesn't exist" do
      it "should create new user" do
        allow(Contact).to receive(:find_by_email).with( email ).and_return( nil )
        contact = Contact.new( email: email )
        expect(Contact).to receive(:new).and_return( contact )
        sync.send(:subscribe)
        expect( contact.first_name ).to eql( first_name )
        expect( contact.last_name ).to eql( last_name )
        expect( contact.email ).to eql( email )
        expect( contact.send(cf_name)[:list_id] ).to eql( list_id )
        expect( contact.send(cf_name)[:source] ).to eql( "webhook" )
        expect( contact.send(cf_name)[:groupings] ).to eql( [cf_groupings] )
      end
    end

    context "when user exists" do

      it "should update existing user" do
        mock_contact = double(Contact)
        expect(mock_contact).to receive_message_chain(:order, :first).and_return(contact)
        expect(Contact).to receive(:where).with( email: email ).and_return( mock_contact )
        expect(Contact).not_to receive(:new)
        sync.send(:subscribe)
        expect( contact.first_name ).to eql( first_name )
        expect( contact.last_name ).to eql( last_name )
        expect( contact.send(cf_name)[:list_id] ).to eql( list_id )
        expect( contact.send(cf_name)[:source] ).to eql( "webhook" )
        expect( contact.send(cf_name)[:groupings] ).to eql( [cf_groupings] )
      end

    end

  end

  describe "profile_update" do

    let(:params)  { FactoryBot.build(:mailchimp_webhook, type: 'profile', data: data) }
    before {
      mock_contact = double(Contact)
      expect(mock_contact).to receive_message_chain(:order, :first).and_return(contact)
      expect(Contact).to receive(:where).with( email: email ).and_return( mock_contact )
      sync.send(:profile_update)
    }
    after { teardown_custom_field_record }

    it { expect( contact.first_name ).to eql( first_name ) }
    it { expect( contact.last_name  ).to eql( last_name ) }
    it { expect( contact.send(cf_name)[:groupings] ).to eql( [cf_groupings] ) }
    it { expect( contact.send(cf_name)[:list_id] ).to eql( list_id ) }

  end

  describe "email_changed" do

    let(:params)   { FactoryBot.build(:mailchimp_webhook, type: 'upemail', data: data) }
    let(:contact2) { FactoryBot.build(:contact) }

    context "when new email doesn't exist" do
      it "should update email" do
        contact = FactoryBot.create(:contact, email: old_email)
        sync.send(:email_changed)
        expect( contact.reload.email ).to eq( new_email )
      end
    end

    context "when new email does exist" do

      it "should unsubscribe the old_email user" do
        old_contact = FactoryBot.create(:contact, email: old_email)
        new_contact = FactoryBot.create(:contact, email: new_email)
        mock_old_contact = double(Contact)
        expect(mock_old_contact).to receive_message_chain(:order, :first).and_return(old_contact)
        mock_new_contact = double(Contact)
        expect(mock_new_contact).to receive_message_chain(:order, :first).and_return(new_contact)
        expect(Contact).to receive(:where).with(email: old_email).and_return( mock_old_contact )
        expect(Contact).to receive(:where).with(email: new_email).and_return( mock_new_contact )
        expect(old_contact).to receive(:update) do |args|
          expect(args[ cf_name ] ).to eql( {} )
        end
        sync.send(:email_changed)
      end

    end

    context "when contact with old_email doesn't exist" do
      it "should ignore the update" do
        expect_any_instance_of(Contact).not_to receive(:update)
        sync.send(:email_changed)
      end
    end

  end

  describe "unsubscribe" do

    let(:params)   { FactoryBot.build(:mailchimp_webhook, type: 'unsubscribe', data: data) }

    context "when user is found" do
      it "should unsubscribe" do
        mock_contact = double(Contact)
        expect(mock_contact).to receive_message_chain(:order, :first).and_return(contact)
        expect(Contact).to receive(:where).with( email: email ).and_return( mock_contact )
        expect(contact).to receive(:update) do |args|
          expect(args[ cf_name ] ).to eql( {} )
        end
        sync.send(:unsubscribe)
      end
    end

    context "when user is not found" do
      it "should not unsubscribe" do
        mock_contact = double(Contact)
        expect(mock_contact).to receive_message_chain(:order, :first).and_return(nil)
        expect(Contact).to receive(:where).with( email: email ).and_return( mock_contact )
        expect_any_instance_of(Contact).not_to receive(:update)
        sync.send(:unsubscribe)
      end
    end

  end

  describe "custom_field" do

    context "when list_id has an associated custom_field" do
      it { expect( sync.send(:custom_field) ).to eql( CustomFieldMailchimpList.where(name: cf_name).first ) }
    end

    context "when list_id does not have an associated custom_field" do
      it {
        expect(sync.data).to receive(:list_id).and_return("123434")
        expect( sync.send(:custom_field) ).to eql( nil )
      }
    end

  end

  describe "contact" do

    context "when more than one contact with same email" do

      let(:contact)  { FactoryBot.create(:contact, email: email) }
      let(:contact2) { FactoryBot.create(:contact, email: email) }

      it "should always pick contact with lowest id" do
        correct_contact = contact.id < contact2.id ? contact : contact2
        expect( sync.send(:contact) ).to eql( correct_contact )
      end

    end

  end

end
