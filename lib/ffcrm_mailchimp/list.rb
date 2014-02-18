require 'ffcrm_mailchimp/group'
require 'ffcrm_mailchimp/cache_monkey'

module FfcrmMailchimp

  # Encapsulates a mailchimp list
  class List

    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end

    # An array of groups belonging to this list
    def groups
      FfcrmMailchimp::Group.groups_for(id)
    end

    class << self

      # All the available lists in Mailchimp
      def lists
        all_lists
      end

      # All lists in form suitable for collection in select list
      def collection_for_select
        all_lists.collect{ |hlist|[hlist.name, hlist.id]}
      end

      # Lookup a list based on id
      def find(id)
        all_lists.select{ |list| list.id == id }.first
      end

      private

      # Ask the Mailchimp API for all available lists
      # Return a hash of list id and list name
      def all_lists
        lists_from_mailchimp["data"].map(&:stringify_keys).map {|list| new(list["id"], list["name"])}
      end

      # Test stubs are easier when this is a function
      def lists_from_mailchimp
        CacheMonkey.lists
      end

    end
  end
end
