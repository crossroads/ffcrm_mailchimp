require 'spec_helper'

describe FfcrmMailchimp::List do

  let(:lists) { FactoryGirl.build_list(:list, 2) }

  before { FfcrmMailchimp::List.stub(:lists_from_mailchimp).and_return( {"data" => lists} ) }

  context "when initialized" do
    let(:list) { FfcrmMailchimp::List.new( id: '123', name: 'test') }
    it { expect( list.id ).to eql('123') }
    it { expect( list.name ).to eql('test') }
  end

  describe ".lists" do
    context "when mailchimp lists exist" do
      it { expect( FfcrmMailchimp::List.lists.count ).to eql( 2 ) }
    end
    context "when no mailchimp lists" do
      let(:lists) { [] }
      it { expect( FfcrmMailchimp::List.lists.count ).to eql( 0 ) }
    end
  end

  describe ".collection_for_select" do
    it "should return only id and name" do
      all_result = FfcrmMailchimp::List.collection_for_select
      expect( all_result ).to_not be_empty
      expect( all_result.first.count ).to eql( 2 )
      expect( all_result.last.count ).to  eql( 2 )
      expect( all_result.class).to eql(Array)
    end
  end

  describe ".find(id)" do
    it "should return list for the given id" do
      id = lists.first[:id]
      list_by_id = FfcrmMailchimp::List.find( id )
      list_by_id.should be_kind_of FfcrmMailchimp::List
      list_by_id.name.should_not be_blank
    end
  end

  describe "members" do

    let(:gibbon)    { double( list: raw_array ) }
    let(:raw_array) { ["[\"EMAIL\",\"FIRST_NAME\",\"LAST_NAME\",\"Group One\",\"Group Two\",\"MEMBER_RATING\",\"OPTIN_TIME\",\"OPTIN_IP\",\"CONFIRM_TIME\",\"CONFIRM_IP\",\"LATITUDE\",\"LONGITUDE\",\"GMTOFF\",\"DSTOFF\",\"TIMEZONE\",\"CC\",\"REGION\",\"LAST_CHANGED\",\"LEID\",\"EUID\"]\n",
 "[\"test@example.com\",\"Test\",\"Name\",\"Option 1, Option 2\",\"\",2,\"\",null,\"2014-02-20 08:23:53\",\"127.0.0.1\",null,null,null,null,null,null,null,\"2014-02-22 04:36:00\",\"135560097\",\"9d79ad51bb\"]\n"] }
    let(:group1) { double( name: 'Group One' ) }
    let(:group2) { double( name: 'Group Two' ) }
    let(:groups) { [group1, group2] }
    let(:merge_vars) { double(FfcrmMailchimp::MergeVars).tap{|d| d.stub(:field_label_for){|args| args.upcase} } }

    it "should create a new member" do
      Gibbon::Export.stub(:new).and_return( gibbon )
      list = FfcrmMailchimp::List.new( id: '12345' )
      list.stub(:groups).and_return( groups )
      FfcrmMailchimp::MergeVars.stub(:new).and_return( merge_vars )
      member = list.members.first
      expect( member.email ).to eql( 'test@example.com' )
      expect( member.first_name ).to eql( 'Test' )
      expect( member.last_name ).to eql( 'Name' )
      expect( member.list_id ).to eql( '12345' )
      expect( member.last_changed ).to eql( DateTime.parse('2014-02-22 04:36:00') )
      expect( member.subscribed_groups ).to eql( {'Group One' => "Option 1, Option 2" } )
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
