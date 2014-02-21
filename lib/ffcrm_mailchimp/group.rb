require 'ostruct'
require 'gibbon'
require 'ffcrm_mailchimp/list'

module FfcrmMailchimp

  # This relates to a group inside a list in Mailchimp
  # It's not meant to be called directly, rather via groups_for inside a List
  class Group < OpenStruct

    # {"id"=>8661,
    #  "name"=>"Group One",
    #  "form_field"=>"checkboxes",
    #  "display_order"=>"0",
    #  "groups"=>
    #    [{"bit"=>"1", "name"=>"Option 1", "display_order"=>"1", "subscribers"=>nil},
    #     {"bit"=>"2", "name"=>"Option 2", "display_order"=>"2", "subscribers"=>nil}]}
    #
    # We also inject 'list_id' when creating a new group instance

    # Returns ["Option 1", "Option 2"]
    def group_names
      groups.collect{ |group| group.stringify_keys['name'] }
    end

    # Return all the groups that belong to a particular list in Mailchimp
    def self.groups_for(list_id)
      groups_from_mailchimp(list_id).map do |group|
        new( group.merge( list_id: list_id ) )
      end
    end

    def clear_cache
      Rails.cache.delete( groups_cache_key )
    end

    private

    class << self

      # Get the groups from mailchimp and cache them
      def groups_from_mailchimp
        return [] if list_id.nil?
        Rails.cache.fetch( groups_cache_key(list_id) ) do
          Rails.logger.info("FfcrmMailchimp: Cache miss fetching groups for list #{list_id}")
          gibbon.lists.interest_groupings(id: list_id)
        end
      end

      def groups_cache_key
        "cache_monkey_groups_for_list_" << list_id
      end

      def gibbon
        @gibbon ||= Gibbon::API.new( api_key )
      end

      def api_key
        FfcrmMailchimp.config.api_key
      end

    end

  end

end
