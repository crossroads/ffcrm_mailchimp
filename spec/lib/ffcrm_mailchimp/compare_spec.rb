require 'spec_helper'
require 'ffcrm_mailchimp/member'

describe FfcrmMailchimp::Compare do

  before(:all) { setup_custom_field_record }
  after(:all)  { teardown_custom_field_record }

  let(:list_id) { '3e26bc072d' }
  let(:groupings) { [{ "id" => "1525", "groups"=> ["group1","group2"] }] }
  let(:subscription_params) { {"list_id" => list_id, "groupings" => groupings, "source"=> "ffcrm"} }
  let(:contact) { FactoryGirl.create(:contact, custom_field: subscription_params) }
  let(:contacts) { [ contact ] }
  let(:member) { FfcrmMailchimp::Member.new(FactoryGirl.attributes_for(:mailchimp_member)) }
  let(:members) { [ member ] }

  let(:compare) { FfcrmMailchimp::Compare.new(list_id) }

  before { allow_any_instance_of(FfcrmMailchimp::Compare).to receive(:members).and_return(members) }

  context "initialization" do
    it "list_id" do
      expect( compare.list_id ).to eql( list_id )
    end
  end

  context "count_members" do
    it { expect( compare.count_members ).to eql( members.count ) }
  end

  context "count_contacts" do
    it { contacts # ensure they exist before we create class
         expect( compare.count_contacts ).to eql( contacts.count ) }
  end

  context "compare" do
    subject { compare.send(:compare) }
    it { expect be_a( Array ) }
    it { expect( subject.count ).to eql( 1 ) }
    it { expect( subject.first ).to be_a( FfcrmMailchimp::Comparision ) }
  end

  context "different" do
    before do
      cmp1 = FfcrmMailchimp::Comparision.new(member, contact)
      allow(cmp1).to receive(:different?).and_return(true)
      cmp2 = FfcrmMailchimp::Comparision.new(member, contact)
      allow(cmp2).to receive(:different?).and_return(false)
      allow(compare).to receive(:compare).and_return( [cmp1, cmp2] )
    end
    subject { compare.different }
    it { expect( subject.count ).to be( 1 ) }
  end

end
