require 'gibbon'
require 'ostruct'
require 'ffcrm_mailchimp/group'
require 'ffcrm_mailchimp/webhook_params'

module FfcrmMailchimp

  # Encapsulates a mailchimp list
  class List < OpenStruct

    # Defined methods
    # id, name, web_id, date_created
    # subscribe_url_short, subscribe_url_long
    # beamer_address

    def group_count
      stats['group_count']
    end

    def member_count
      stats['member_count']
    end

    def unsubscribe_count
      stats['unsubscribe_count']
    end

    def has_groups?
      stats['grouping_count'] > 0
    end

    # An array of Group objects belonging to this list
    # Check if a list has any groups before asking for them as Mailchimp
    # returns an error
    def groups
      return [] unless has_groups?
      FfcrmMailchimp::Group.groups_for(id)
    end

    # Query list members directly from Mailchimp
    # Returns an array of WebhookParams
    def members
      gibbon.lists.members( id: id )['data'].map do |data|
        WebhookParams.new( 'data' => data )
      end
    end

    def clear_cache
      lists.each { |list| list.groups.map(&:clear_cache) }
      Rails.cache.delete( lists_cache_key )
    end

    # Clears and visits each list and group to fill the caches again
    def reload_cache
      clear_cache
      lists.each{ |list| list.groups }
    end

    class << self

      # All the available lists from Mailchimp
      # NOTE: this is not the same as the actual lists configured for use in CRM.
      # Look at FfcrmMailchimp::Config.mailchimp_list_fields for that
      def lists
        all_lists
      end

      # All lists in form suitable for collection in select list
      def collection_for_select
        all_lists.collect{ |list| [list.name, list.id] }
      end

      # Lookup a list based on id
      def find(id)
        all_lists.select{ |list| list.id == id }.first
      end

      private

      # Ask the Mailchimp API for all available lists
      # and instantiate an array of List objects
      def all_lists
        lists_from_mailchimp["data"].map(&:stringify_keys).map { |list| new( list ) }
      end

      # Test stubs are easier when this is a function
      def lists_from_mailchimp
        Rails.cache.fetch( lists_cache_key ) do
          Rails.logger.info("FfcrmMailchimp: Cache miss fetching lists")
          gibbon.lists.list
        end
      end

      def lists_cache_key
        "cache_monkey_lists"
      end

      def config
        FfcrmMailchimp.config
      end

      def gibbon
        @gibbon ||= Gibbon::API.new( config.api_key )
      end

    end
  end
end
