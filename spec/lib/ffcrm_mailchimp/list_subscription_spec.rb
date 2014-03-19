require 'ffcrm_mailchimp/list_subscription'

describe FfcrmMailchimp::ListSubscription do

  let(:list_id)  { "3e26bc072d" }
  let(:source) { "ffcrm" }
  let(:grouping1) { { "id" => "1525", "groups"=> ["group1","group2"] } }
  let(:grouping2) { { "id" => "1243", "groups"=> ["group3","group4"] } }
  let(:grouping_params) { {"list_id" => list_id, "groupings" => [grouping1, grouping2], "source"=> source} }
  let(:subscription) { FfcrmMailchimp::ListSubscription.new( grouping_params ) }

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

  context "from_form" do
    let(:form_params) { { "list_id" => list_id, "groups" => {"8661"=>["Option 1", ""], "8669"=>["Option 3", ""]}, "source" => source } }
    let(:subscription) { FfcrmMailchimp::ListSubscription.from_form( form_params ) }
    it { expect( subscription.list_id ).to eql( list_id ) }
    it { expect( subscription.source ).to eql( source ) }
    it { expect( subscription.groupings ).to eql( [ { "id" => "8661", "groups" => ["Option 1"] }, { "id" => "8669", "groups" => ["Option 3"] } ] ) }
  end

end
