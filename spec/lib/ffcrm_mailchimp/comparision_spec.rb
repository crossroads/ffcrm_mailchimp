require 'spec_helper'

describe FfcrmMailchimp::Comparision do

  before(:all) { setup_custom_field_record }
  after(:all)  { teardown_custom_field_record }

  let(:list_id) { '3e26bc072d' }
  let(:groupings) { [{ "id" => "1525", "groups"=> ["group1","group2"] }] }
  let(:subscription_params) { {"list_id" => list_id, "groupings" => groupings, "source"=> "ffcrm"} }
  let(:contact) { FactoryGirl.create(:contact, custom_field: subscription_params) }
  let(:contacts) { [ contact ] }
  let(:member) { FfcrmMailchimp::Member.new(FactoryGirl.attributes_for(:mailchimp_member)) }
  let(:members) { [ member ] }

  let(:comparision) { FfcrmMailchimp::Comparision.new(member, contact) }

  before { FfcrmMailchimp::Comparision.any_instance.stub(:members).and_return(members) }

  context "initialization" do
    it "list_id" do
      expect( comparision.member ).to eql( member )
      expect( comparision.contact ).to eql( contact )
    end
  end

  it { expect( comparision.id ).to eql( contact.id ) }
  it { expect( comparision.contact_email ).to eql( contact.email ) }
  it { expect( comparision.member_email ).to eql( member.email ) }

  context "differences" do
    subject { comparision.differences }
    context "only in mailchimp" do
      let(:contact) { nil }
      it { expect( subject.keys ).to eql( [:base] ) }
      it { expect( subject.values ).to eql( [['Exists only in Mailchimp', '']] ) }
    end
    context "only in ffcrm" do
      let(:member) { nil }
      it { expect( subject.keys ).to eql( [:base] ) }
      it { expect( subject.values ).to eql( [['', 'Exists only in FFCRM']] ) }
    end
  end

  context "compare_first_name" do
    let(:new_name) { "#{member.first_name}-TEST" }
    before { member.stub(:first_name).and_return( new_name ) }
    subject { comparision.send(:compare_first_name) }
    it { expect( subject.keys ).to eql( [:first_name] ) }
    it { expect( subject.values ).to eql( [[new_name, contact.first_name]] ) }
  end

  context "compare_last_name" do
    let(:new_name) { "#{member.last_name}-TEST" }
    before { member.stub(:last_name).and_return( new_name ) }
    subject { comparision.send(:compare_last_name) }
    it { expect( subject.keys ).to eql( [:last_name] ) }
    it { expect( subject.values ).to eql( [[new_name, contact.last_name]] ) }
  end

  context "compare_groups" do
    before {
      comparision.stub(:mailchimp_groups).and_return( Set.new(['group1', 'group2']) )
      comparision.stub(:contact_groups).and_return( Set.new(['group2', 'group3']) )
    }
    subject { comparision.send(:compare_groups) }
    it { expect( subject.keys ).to eql( [:groups] ) }
    it { expect( subject.values ).to eql( [['group1, group2', 'group2, group3']] ) }
  end

end
