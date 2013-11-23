module FfcrmMailchimp

  #
  # This relates to a group inside a list in mailchimp
  class MailchimpGroup

    attr_accessor :id, :name, :list_id

    def initialize(id, name, list_id)
      @id = id
      @name = name
      @list_id = list_id
    end

    #
    # Return all the groups that belong to a particular list in Mailchimp
    def self.groups_for(list_id)
      self._groups.select{ |group| group.list_id == list_id }
    end

    private

    #
    # Ask the Mailchimp API for all available lists
    # Return a hash of list id and list name
    def self._groups
      @groups ||= begin
        # dummy groups: id, name, list_id
        [ new('130284', 'Group A', '157894'),
          new('128903', 'Group B', '157894'),
          new('423423', 'Group C', '789456'),
          new('957303', 'Group D', '789456') ]
      end
    end

  end

end
