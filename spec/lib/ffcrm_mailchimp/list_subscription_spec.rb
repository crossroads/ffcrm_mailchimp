require 'ffcrm_mailchimp/list_subscription'

describe FfcrmMailchimp::ListSubscription do

  let(:list_id)  { "3e26bc072d" }
  let(:source) { "ffcrm" }
  let(:group_id) { "1525" }
  let(:groups)   { ["group1","group2"] }
  let(:groupings) { [{ "group_id" => group_id, "groups"=> groups }] }
  let(:grouping_params) { {"list_id" => list_id, "groupings" => groupings, "source"=> source} }
  let(:subscription) { FfcrmMailchimp::ListSubscription.from_array( [grouping_params] ) }

  context "source_is_ffcrm?" do
    it { expect( subscription.source_is_ffcrm? ).to eql(true) }
    it {
      subscription.source = "mailchimp"
      expect( subscription.source_is_ffcrm? ).to eql(false)
    }
  end

  context "has_list?" do
    it { expect( subscription.has_list? ).to eql(true) }
    it {
      subscription.list_id = nil
      expect( subscription.has_list? ).to eql(false)
    }
  end

  context "has_groupings?" do
    it { expect( subscription.has_groupings? ).to eql(true) }
    it {
      subscription.groupings = []
      expect( subscription.has_groupings? ).to eql(false)
    }
  end

  context "wants_to_subscribe?" do
    it { expect( subscription.wants_to_subscribe? ).to eql(true) }
    it {
      subscription.source = 'mailchimp'
      expect( subscription.wants_to_subscribe? ).to eql(false)
    }
    it {
      subscription.list_id = nil
      subscription.groupings = nil
      expect( subscription.wants_to_subscribe? ).to eql(false)
    }
  end

  context "group_id" do
    it { expect( subscription.group_id ).to eql( group_id ) }
    it {
      subscription.groupings = nil
      expect( subscription.group_id ).to eql( nil )
    }
  end

  context "groups" do
    it { expect( subscription.groups ).to eql( groups ) }
    it {
      subscription.groupings = [{ "group_id" => group_id, "groups"=> [] }]
      expect( subscription.groups ).to eql( [] )
    }
  end

  context "to_a" do
    it { expect( subscription.to_a.first['list_id'] ).to eql( list_id ) }
    it { expect( subscription.to_a.first['source'] ).to eql( source ) }
    it { expect( subscription.to_a.first['groupings'] ).to eql( groupings ) }
  end

  context "from_array" do
    it { expect( subscription.list_id ).to eql( list_id ) }
    it { expect( subscription.source ).to eql( source ) }
    it { expect( subscription.groupings ).to eql( groupings ) }
  end

end
