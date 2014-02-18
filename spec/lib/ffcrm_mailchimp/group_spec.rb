require 'spec_helper'

describe FfcrmMailchimp::Group do

  let(:interest_groupings){ FactoryGirl.build_list(:interest_groupings, 4) }

  before { FfcrmMailchimp::Group.stub(:groups_from_mailchimp).and_return( [{"groups" => interest_groupings}] ) }

  describe ".groups_for" do

    context "when mailchimp groups exist" do
      it { expect( FfcrmMailchimp::Group.groups_for("test1234").count ).to eql( 4 ) }
    end

    context "when no groups exists" do
      before { FfcrmMailchimp::Group.stub(:groups_from_mailchimp).and_return( [{"groups" => []}] ) }
      it { expect( FfcrmMailchimp::Group.groups_for("test1234") ).to be_empty }
    end

  end

end
