require 'spec_helper'

describe FfcrmMailchimp::InboundSync do

  before(:all) { setup_custom_field_record }
  after(:all)  { teardown_custom_field_record }

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
                 merges: { EMAIL: email, FNAME: first_name, LNAME: last_name,
                           INTERESTS: interests, GROUPINGS: groupings }
             } }

  let(:params)  { FactoryGirl.build(:mc_webhook, data: data) }
  let(:sync)    { FfcrmMailchimp::InboundSync.new( params ) }
  let(:contact) { FactoryGirl.build(:contact) }

  describe "process" do

    before { sync.stub(:custom_field).and_return( double(CustomField) ) }

    context "when type is 'subscribe'" do
      let(:params) { FactoryGirl.build(:mc_webhook, type: 'subscribe') }
      it { expect( sync ).to receive(:subscribe)
           sync.process }
    end

    context "when type is 'profile'" do
      let(:params) { FactoryGirl.build(:mc_webhook, type: 'profile') }
      it { expect( sync ).to receive(:profile_update)
           sync.process }
    end

    context "when type is 'upemail'" do
      let(:params) { FactoryGirl.build(:mc_webhook, type: 'upemail') }
      it { expect( sync ).to receive(:email_changed)
           sync.process }
    end

    context "when type is 'unsubscribe'" do
      let(:params) { FactoryGirl.build(:mc_webhook, type: 'unsubscribe') }
      it { expect( sync ).to receive(:unsubscribe)
           sync.process }
    end

    context "when no custom field exists for this list" do

      it "should do nothing" do
        sync.should_receive(:custom_field).and_return( nil )
        sync.should_not_receive(:subscribe)
        sync.should_not_receive(:profile_update)
        sync.should_not_receive(:email_changed)
        sync.should_not_receive(:unsubscribe)
        sync.process
      end

    end


  end

  describe "subscribe" do

    let(:params)  { FactoryGirl.build(:mc_webhook, type: 'subscribe', data: data) }

    context "when user doesn't exist" do
      it "should create new user" do
        Contact.stub(:find_by_email).with( email ).and_return( nil )
        contact = Contact.new( email: email )
        Contact.should_receive(:new).and_return( contact )
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
        mock_contact = double.tap{ |d| d.stub_chain('order.first').and_return(contact) }
        Contact.should_receive(:where).with( email: email ).and_return( mock_contact )
        Contact.should_not_receive(:new)
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

    let(:params)  { FactoryGirl.build(:mc_webhook, type: 'profile', data: data) }
    before {
      mock_contact = double.tap { |d| d.stub_chain('order.first').and_return(contact) }
      Contact.stub(:where).with( email: email ).and_return( mock_contact )
      sync.send(:profile_update)
    }
    after { teardown_custom_field_record }

    it { expect( contact.first_name ).to eql( first_name ) }
    it { expect( contact.last_name  ).to eql( last_name ) }
    it { expect( contact.send(cf_name)[:groupings] ).to eql( [cf_groupings] ) }
    it { expect( contact.send(cf_name)[:list_id] ).to eql( list_id ) }

  end

  describe "email_changed" do

    let(:params)   { FactoryGirl.build(:mc_webhook, type: 'upemail', data: data) }
    let(:contact2) { FactoryGirl.build(:contact) }
    let(:old_email_contact) { stub_chain('order.first').and_return(contact) }
    let(:new_email_contact) { stub_chain('order.first').and_return(nil) }

    context "when new email doesn't exist" do
      it "should update email" do
        contact = FactoryGirl.create(:contact, email: old_email)
        sync.send(:email_changed)
        expect( contact.reload.email ).to eq( new_email )
      end
    end

    context "when new email does exist" do

      it "should unsubscribe the old_email user" do
        old_contact = FactoryGirl.create(:contact, email: old_email)
        new_contact = FactoryGirl.create(:contact, email: new_email)
        mock_old_contact = double.tap{ |d| d.stub_chain('order.first').and_return(old_contact) }
        mock_new_contact = double.tap{ |d| d.stub_chain('order.first').and_return(new_contact) }
        Contact.stub(:where).with(email: old_email).and_return( mock_old_contact )
        Contact.stub(:where).with(email: new_email).and_return( mock_new_contact )
        old_contact.should_receive(:update_attributes) do |args|
          expect(args[ cf_name ] ).to eql( {} )
        end
        sync.send(:email_changed)
      end

    end

    context "when contact with old_email doesn't exist" do
      it "should ignore the update" do
        Contact.any_instance.should_not_receive(:update_attributes)
        sync.send(:email_changed)
      end
    end

  end

  describe "unsubscribe" do

    let(:params)   { FactoryGirl.build(:mc_webhook, type: 'unsubscribe', data: data) }

    context "when user is found" do
      it "should unsubscribe" do
        mock_contact = double.tap{ |d| d.stub_chain('order.first').and_return(contact) }
        Contact.should_receive(:where).with( email: email ).and_return( mock_contact )
        contact.should_receive(:update_attributes) do |args|
          expect(args[ cf_name ] ).to eql( {} )
        end
        sync.send(:unsubscribe)
      end
    end

    context "when user is not found" do
      it "should not unsubscribe" do
        mock_contact = double.tap{ |d| d.stub_chain('order.first').and_return(nil) }
        Contact.should_receive(:where).with( email: email ).and_return( mock_contact )
        Contact.any_instance.should_not_receive(:update_attributes)
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
        sync.data.stub(:list_id).and_return("123434")
        expect( sync.send(:custom_field) ).to eql( nil )
      }
    end

  end

  describe "contact" do

    context "when more than one contact with same email" do

      let(:contact)  { FactoryGirl.create(:contact, email: email) }
      let(:contact2) { FactoryGirl.create(:contact, email: email) }

      it "should always pick contact with lowest id" do
        correct_contact = contact.id < contact2.id ? contact : contact2
        expect( sync.send(:contact) ).to eql( correct_contact )
      end

    end

  end

end
