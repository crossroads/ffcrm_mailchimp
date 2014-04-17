require 'json'
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

    # Query Mailchimp Export API to get all membership details
    # Returns an array of Member
    def members
      gibbon = Gibbon::Export.new( FfcrmMailchimp::config.api_key )
      export = gibbon.list( id: id )

      email_offset       = get_offset(export, 'Email Address') # 0
      first_name_offset  = get_offset(export, 'First Name')    # 1
      last_name_offset   = get_offset(export, 'Last Name')     # 2
      last_changed_offset = get_offset(export, 'LAST_CHANGED') # 17

      # Return [ ["Group 1", 3], ["Group 2", 4] ]
      groups_with_offsets = groups.map(&:name).map do |name|
        offset = get_offset(export, name)
        offset.present? ? [name, offset] : nil
      end.compact

      export.drop(1).map do |line|
        json = JSON.parse(line)
        # {'Group One' => "Option 1, Option 2", "Group Two" => "Option 3" }
        groups = {}
        groups_with_offsets.map do |name, offset|
          interest_groups = json[offset]
          groups.merge!( interest_groups.blank? ? {} : { name => interest_groups } ) # Ensure { "Group Two" => "" } is excluded
        end
        FfcrmMailchimp::Member.new(
          list_id: id,
          email: json[email_offset],
          first_name: json[first_name_offset],
          last_name: json[last_name_offset],
          subscribed_groups: groups,
          last_changed: DateTime.parse( json[last_changed_offset] ) )
      end
    end

    # Given the export in JSON format, extract the column index for a given column name
    def get_offset(export, column_name)
      @headers ||= JSON.parse( export[0] )
      @headers.index( column_name )
    end

    # Formats a url for the list
    # e.g. https://us3.admin.mailchimp.com/lists/members/?id=346453
    def url
      region = FfcrmMailchimp.config.api_key[-3..-1] # e.g. us3
      "https://#{region}.admin.mailchimp.com/lists/members/?id=#{web_id}"
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

      def clear_cache
        lists.each { |list| list.groups.map(&:clear_cache) }
        Rails.cache.delete( lists_cache_key )
      end

      # Clears and visits each list and group to fill the caches again
      def reload_cache
        clear_cache
        lists.each{ |list| list.groups }
      end

      def gibbon
        @gibbon ||= Gibbon::API.new( config.api_key )
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
        "ffcrm_mailchimp_lists"
      end

      def config
        FfcrmMailchimp.config
      end

    end
  end
end
