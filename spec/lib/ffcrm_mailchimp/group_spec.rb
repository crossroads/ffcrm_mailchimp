require 'spec_helper'

describe FfcrmMailchimp::Group do
  let!(:ffcrm_mailchimp){ FactoryGirl.create(:ffcrm_mailchimp)}
  let(:b_list){[]}
  let(:interest_groupings){ FactoryGirl.build_list(:interest_groupings, 4)}

  before(:each) do
    debugger
    Gibbon::API.any_instance.stub_chain(:lists, :interest_groupings).and_return([{"groups" => interest_groupings}])
  end

  describe ".groups_for" do
    context "mailchimp account" do
      it "should return all the lists" do
        debugger
        FfcrmMailchimp::Group.groups_for("test1234").should_not be_blank
      end
    end
  end
end