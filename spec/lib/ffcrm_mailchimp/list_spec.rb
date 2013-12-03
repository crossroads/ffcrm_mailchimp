require 'spec_helper'

describe FfcrmMailchimp::List do

  let!(:ffcrm_mailchimp){ FactoryGirl.create(:ffcrm_mailchimp)}
  let(:b_list){[]}
  let(:lists){ FactoryGirl.build_list(:list, 2)}

  before(:each) do
    Gibbon::API.any_instance.stub_chain('lists.list').and_return({"data" => lists})
  end

  describe "initialize" do
  end

  describe ".lists" do
    context "mailchimp account" do
      it "should return all the lists" do
        FfcrmMailchimp::List.lists.should_not be_blank
        FfcrmMailchimp::List.lists.count.should eq 2
      end
      it "should return nil if no lists" do
        Gibbon::API.any_instance.stub_chain('lists.list').and_return({ "data" =>b_list })
        FfcrmMailchimp::List.lists.should be_blank
      end
    end
  end

  describe ".all" do
    it "should return only id and name" do
      all_result = FfcrmMailchimp::List.all
      all_result.should_not be_blank
      all_result.first.count.should eq 2
      all_result.last.count.should eq 2
      all_result.should be_kind_of Array
    end
  end

  describe ".get(id)" do
    it "should return list for the given id" do
      list_by_id = FfcrmMailchimp::List.get("test1234")
      list_by_id.should be_kind_of FfcrmMailchimp::List
      list_by_id.name.should_not be_blank
    end
  end

  describe ".group" do
    context "when list id given" do
      it "should return all groups" do

      end
      it "should return nil if no group available" do
      end
      it "should return empty hash if no list id passed" do
      end
    end
  end
end