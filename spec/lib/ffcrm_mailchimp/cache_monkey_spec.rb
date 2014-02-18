require 'spec_helper'

describe FfcrmMailchimp::CacheMonkey do

  let(:mock_gibbon) { double }
  let(:lists_cache_key) { FfcrmMailchimp::CacheMonkey.send(:lists_cache_key) }

  before { FfcrmMailchimp::CacheMonkey.stub(:gibbon).and_return(mock_gibbon) }

  describe "clear" do

    it "should clear the cache" do
      group_id = '123456'
      FfcrmMailchimp::CacheMonkey.stub(:lists).and_return( "data" => [{'id' => group_id}] )
      Rails.cache.should_receive(:delete).with( lists_cache_key ).twice
      Rails.cache.should_receive(:delete).with( "cache_monkey_groups_for_list_" << group_id )
      FfcrmMailchimp::CacheMonkey.clear
    end

  end

end
