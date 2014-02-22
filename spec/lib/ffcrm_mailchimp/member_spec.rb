require 'spec_helper'

describe FfcrmMailchimp::Member do

  context "initialization" do
    subject { FfcrmMailchimp::Member.new( list_id: '1234', email: 'test@example.com' ) }
    it { expect( subject.list_id ).to eql( '1234' ) }
    it { expect( subject.email ).to eql( 'test@example.com' ) }
  end

  context "groupings" do

    let(:subscribed_groups) { {'Group One' => "Option 1, Option 2", "Group Two" => "Option 3" } }
    let(:member_params) { FactoryGirl.build(:mailchimp_member, subscribed_groups: subscribed_groups) }
    let(:member)        { FfcrmMailchimp::Member.new(member_params) }

    before {
      member.stub(:find_group_by_name).with('Group One').and_return( double(id: 1111) )
      member.stub(:find_group_by_name).with('Group Two').and_return( double(id: 2222) )
    }

    subject { member.groupings }
    it { expect( subject['0']['id'] ).to eql( '1111' ) }
    it { expect( subject['0']['name'] ).to eql( 'Group One' ) }
    it { expect( subject['0']['groups'] ).to eql( 'Option 1, Option 2' ) }
    it { expect( subject['1']['id'] ).to eql( '2222' ) }
    it { expect( subject['1']['name'] ).to eql( 'Group Two' ) }
    it { expect( subject['1']['groups'] ).to eql( 'Option 3' ) }

  end

  context "to_webhook_params" do

    let(:subscribed_groups) { {'Group One' => "Option 1, Option 2", "Group Two" => "Option 3" } }
    let(:member_params) { FactoryGirl.build(:mailchimp_member, subscribed_groups: subscribed_groups, email: 'test@example.com', first_name: 'First name', last_name: 'Last name', list_id: '112233') }
    let(:member)        { FfcrmMailchimp::Member.new(member_params) }

    before {
      member.stub(:find_group_by_name).with('Group One').and_return( double(id: 1111) )
      member.stub(:find_group_by_name).with('Group Two').and_return( double(id: 2222) )
    }

    subject { member.to_webhook_params }
    it { expect( subject.email ).to eql( 'test@example.com' ) }
    it { expect( subject.first_name ).to eql( 'First name' ) }
    it { expect( subject.last_name ).to eql( 'Last name' ) }
    it { expect( subject.list_id ).to eql( '112233' ) }

  end

end
