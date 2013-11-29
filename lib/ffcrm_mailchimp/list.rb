require 'ffcrm_mailchimp/group'
require 'mailchimp'
module FfcrmMailchimp

  #
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
        self._lists.map(&:stringify_keys).collect { |hlist|[hlist["name"], hlist["id"]]}
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

    #
    # An array of groups belonging to this list
    def groups
      FfcrmMailchimp::Group.groups_for(id)
    end

    private
    # Ask the Mailchimp API for all available lists
    # Return a hash of list id and list name
    def self._lists
      @lists = _config.lists["data"]
    end

    def self._config
      Mailchimp::API.new(Config.new.api_key)
    end
  end
end
