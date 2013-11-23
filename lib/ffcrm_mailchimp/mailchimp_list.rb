module FfcrmMailchimp

  class MailchimpList

    attr_accessor :id, :name

    class << self

      #
      # All the available lists in Mailchimp
      def lists
        self._lists
      end

      #
      # All lists in form suitable for collection in select list
      def all
        self._lists.collect{ |list| [list.name, list.id] }
      end

      #
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
    # A hash of groups belonging to this list
    # { '130284' => 'Group A', '128903' => 'Group B' }
    def groups
      { '130284' => 'Group A', '128903' => 'Group B' } # dummy groups
    end

    private

    #
    # Ask the Mailchimp API for all available lists
    # Return a hash of list id and list name
    def self._lists
      @lists ||= begin
        # dummy list
        [ new('157894', 'List A'),
          new('789456', 'List B') ]
      end
    end

    #
    # Ask the Mailchimp API for all available groups for this list
    # Return a hash of group id and group name
    def get_groups_from_mailchimp_api
      { '130284' => 'Group A', '128903' => 'Group B' } # list_id
    end

  end

end
