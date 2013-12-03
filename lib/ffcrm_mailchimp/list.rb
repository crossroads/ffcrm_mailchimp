require 'ffcrm_mailchimp/group'
require 'gibbon'
module FfcrmMailchimp

  # This relates to a list in mailchimp
  class List

    attr_accessor :id, :name

    class << self
      # All the available lists in Mailchimp
      def lists
        self._lists
      end

      # All lists in form suitable for collection in select list
      def all
        self._lists.collect{ |hlist|[hlist.name, hlist.id]}
      end

      # Lookup a list based on id
      def get(id)
        self._lists.select{ |list| list.id == id }.first
      end
    end

    def initialize(id, name)
      @id = id
      @name = name
    end

    # An array of groups belonging to this list
    def groups
      FfcrmMailchimp::Group.groups_for(id)
    end

    private
    # Ask the Mailchimp API for all available lists
    # Return a hash of list id and list name
    def self._lists
      @lists = _config.lists.list({:start => 0, :limit => 100})["data"].map(&:stringify_keys).map {|list| new(list["id"], list["name"])}
    end

    def self._config
      Gibbon::API.new(Config.new.api_key)
    end
  end
end
