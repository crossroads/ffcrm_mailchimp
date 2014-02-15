require 'spec_helper'

describe FfcrmMailchimp::InboundSync do

  let(:email)      { "test@example.com" }
  let(:new_email)  { "new_test@example.com" }
  let(:old_email)  { "test@example.com" }
  let(:list_id)    { "3e26bc072d" }
  let(:first_name) { "Bob" }
  let(:last_name)  { "Lee" }
  let(:interests) { "group1, group2" }
  let(:group_id)  { "5641" }
  let(:groupings) { {"0"=> { "id" => group_id, "name" => "Groups", "groups" => interests } } }
  let(:cf_groupings) { {"group_id" => group_id, "groups" => interests.split(', ') } }

  let(:data) { { email: email, new_email: new_email, old_email: old_email, list_id: list_id,
                 merges: { EMAIL: email, FNAME: first_name, LNAME: last_name,
                           INTERESTS: interests, GROUPINGS: groupings }
             } }

  let(:params)  { FactoryGirl.build(:mc_webhook, data: data) }
  let(:sync)    { FfcrmMailchimp::InboundSync.new( params ) }
  let(:contact) { FactoryGirl.build(:contact) }

  describe "process" do

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

  end

  describe "subscribe" do

    let(:params)  { FactoryGirl.build(:mc_webhook, type: 'subscribe', data: data) }

    # Setup real custom fields - it's complicated.
    before { @cf = create_custom_field }
    after  { delete_custom_field }

    context "when user doesn't exist" do
      it "should create new user" do
        Contact.stub(:find_by_email).with( email ).and_return( nil )
        contact = Contact.new( email: email )
        Contact.should_receive(:new).and_return( contact )
        sync.send(:subscribe)
        expect( contact.first_name ).to eql( first_name )
        expect( contact.last_name ).to eql( last_name )
        expect( contact.email ).to eql( email )
        expect( contact.send(@cf.name).first["list_id"] ).to eql( list_id )
        expect( contact.send(@cf.name).first["source"] ).to eql( "webhook" )
        expect( contact.send(@cf.name).first["groupings"] ).to eql( [cf_groupings] )
      end
    end

    context "when user exists" do

      it "should update existing user" do
        Contact.should_receive(:find_by_email).with( email ).and_return( contact )
        Contact.should_not_receive(:new)
        sync.send(:subscribe)
        expect( contact.first_name ).to eql( first_name )
        expect( contact.last_name ).to eql( last_name )
        expect( contact.send(@cf.name).first["list_id"] ).to eql( list_id )
        expect( contact.send(@cf.name).first["source"] ).to eql( "webhook" )
        expect( contact.send(@cf.name).first["groupings"] ).to eql( [cf_groupings] )
      end

    end

    context "when no custom field for this list" do

      it "should do nothing" do
        sync.should_receive(:custom_field).and_return( nil )
        Contact.should_not_receive(:find_by_email)
        sync.send(:subscribe)
      end

    end

  end

  describe "profile_update" do

    let(:params)  { FactoryGirl.build(:mc_webhook, type: 'profile', data: data) }

    context "when custom field exists" do
      before {
        @cf = create_custom_field
        Contact.stub(:find_by_email).with( email ).and_return( contact )
        sync.send(:profile_update)
      }
      after { delete_custom_field }
      it { expect( contact.first_name ).to eql( first_name ) }
      it { expect( contact.last_name  ).to eql( last_name ) }
      it { expect( contact.send(@cf.name).first['groupings'] ).to eql( [cf_groupings] ) }
      it { expect( contact.send(@cf.name).first['list_id'] ).to eql( list_id ) }
    end

    context "when custom field doesn't exist" do
      before {
        Contact.stub(:find_by_email).with( email ).and_return( contact )
        sync.stub(:custom_field).and_return( nil )
      }
      it { contact.should_not_receive(:save)
           sync.send(:profile_update) }
    end

  end

  describe "email_changed" do

    let(:params)   { FactoryGirl.build(:mc_webhook, type: 'upemail', data: data) }
    let(:contact2) { FactoryGirl.build(:contact) }

    context "when new email doesn't exist" do
      it "should update email" do
        Contact.should_receive(:find_by_email).with( old_email ).and_return( contact )
        Contact.should_receive(:find_by_email).with( new_email ).and_return( nil )
        sync.send(:email_changed)
        expect( contact.email ).to eq( new_email )
      end
    end

    context "when new email does exist" do
      it "should not update email" do
        Contact.should_receive(:find_by_email).with( old_email ).and_return( contact )
        Contact.should_receive(:find_by_email).with( new_email ).and_return( contact2 )
        sync.send(:email_changed)
        expect( contact.email ).to_not eq( new_email )
      end
    end

    context "when contact doesn't exist" do
      it "should ignore the update" do
        Contact.should_receive(:find_by_email).with( old_email ).and_return( nil )
        Contact.should_receive(:find_by_email).with( new_email ).and_return( nil )
        Contact.any_instance.should_not_receive(:update_attributes)
        sync.send(:email_changed)
      end
    end

  end

  describe "unsubscribe" do

    before { @cf = create_custom_field }
    after  { delete_custom_field }

    let(:params)   { FactoryGirl.build(:mc_webhook, type: 'unsubscribe', data: data) }

    context "when user is found" do
      it "should unsubscribe" do
        Contact.should_receive(:find_by_email).with( email ).and_return( contact )
        contact.should_receive(:update_attributes) do |args|
          expect(args["#{@cf.name}="] ).to eql( [] )
        end
        sync.send(:unsubscribe)
      end
    end

    context "when user is not found" do
      it "should not unsubscribe" do
        Contact.should_receive(:find_by_email).with( email ).and_return( nil )
        Contact.any_instance.should_not_receive(:update_attributes)
        sync.send(:unsubscribe)
      end
    end

  end

  describe "custom_field" do

    context "when list_id has an associated custom_field" do
      before { @cf = create_custom_field }
      after  { delete_custom_field }
      it { expect( sync.send(:custom_field) ).to eql( @cf ) }
    end

    context "when list_id does not have an associated custom_field" do
      it { expect( sync.send(:custom_field) ).to eql( nil ) }
    end

  end

  #
  # For some of the tests above we need to have a real mailchimp list custom field set up.
  # This requires altering the database columns for the Contact class which need cleaning
  # up afterwards.
  def create_custom_field
    field_group = FactoryGirl.create(:field_group, klass_name: "Contact")
    list = { list_id: "3e26bc072d" }.with_indifferent_access
    CustomFieldMailchimpList.create( as: 'mailchimp_list', field_group_id: field_group.id,
      label: "custom_field", name: "custom_field_#{rand(1234)}", settings: list )
  end

  def delete_custom_field
    CustomFieldMailchimpList.all.each do |field|
      field.klass.connection.remove_column(field.send(:table_name), field.name)
      field.klass.reset_column_information
    end
    CustomFieldMailchimpList.delete_all
    FieldGroup.delete_all
  end

end
