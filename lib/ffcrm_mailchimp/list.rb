require 'json'
require 'ostruct'
require 'ffcrm_mailchimp/api'
require 'ffcrm_mailchimp/group'
require 'ffcrm_mailchimp/webhook_params'

module FfcrmMailchimp

  # Encapsulates a mailchimp list
  class List < OpenStruct

    # Defined attributes
    # id, name

    def has_groups?
      groups.any?
    end

    # An array of Group objects belonging to this list
    # Check if a list has any groups before asking for them as Mailchimp
    # returns an error
    def groups
      FfcrmMailchimp::Group.groups_for(id)
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
        all_lists.sort{|x,y| x['name'] <=> y['name']}.collect{ |list| [list.name, list.id] }
      end

      # Lookup a list based on id
      def find(id)
        all_lists.select{ |list| list.id == id }.first
      end

      private

      # Ask the Mailchimp API for all available lists
      # and instantiate an array of List objects
      def all_lists
        FfcrmMailchimp::Api.all_lists.map(&:stringify_keys).map { |list| new( list ) }
      end

    end
  end
end
