require 'spec_helper'

describe FfcrmMailchimp::Group do

  let(:group) { FfcrmMailchimp::Group.new( mailchimp_group ) }
  let(:mailchimp_group) { FactoryGirl.build(:mailchimp_group) }

  before { FfcrmMailchimp::Group.stub(:groups_from_mailchimp).and_return( [mailchimp_group] ) }

  describe "initialization" do
    it { expect( group.id ).to eql( mailchimp_group[:id] ) }
    it { expect( group.name ).to eql( mailchimp_group[:name] ) }
    it { expect( group.form_field ).to eql( mailchimp_group[:form_field] ) }
    it { expect( group.groups ).to eql( mailchimp_group[:groups] ) }
  end

  describe ".groups_for" do

    context "when mailchimp groups exist" do
      it { expect( FfcrmMailchimp::Group.groups_for('1234').first.id ).to eql( mailchimp_group[:id] ) }
    end

    context "when no groups exists" do
      before { FfcrmMailchimp::Group.stub(:groups_from_mailchimp).and_return( [] ) }
      it { expect( FfcrmMailchimp::Group.groups_for('1234') ).to eql( [] ) }
    end

  end

  describe "group_names" do

    let(:group1) { FactoryGirl.build(:interest_grouping, name: "Option 1") }
    let(:group2) { FactoryGirl.build(:interest_grouping, name: "Option 2") }
    let(:mailchimp_group) { FactoryGirl.build(:mailchimp_group, groups: [group1, group2] ) }

    it { expect( group.group_names ).to include("Option 1") }
    it { expect( group.group_names ).to include("Option 2") }

  end

end
