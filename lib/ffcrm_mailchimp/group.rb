module FfcrmMailchimp

  # This relates to a group inside a list in mailchimp
  class Group

    attr_accessor :id, :name, :list_id

    def initialize(id, name, list_id)
      @id = id
      @name = name
      @list_id = list_id
    end

    # Return all the groups that belong to a particular list in Mailchimp
    def self.groups_for(list_id)
      self._groups(list_id).select{ |group| group.list_id == list_id }
    end

    private

    # Ask the Mailchimp API for all available groups for a give list_id
    # Return a hash of groups with the group details and list id
    def self._groups(list_id)
      groups = _config.lists.interest_groupings(id: list_id).first["groups"]
      groups.map(&:stringify_keys).map {|grp| new(grp["bit"], grp["name"], list_id)}
    end

    def self._config
      Config.new.mailchimp_api
    end
  end

end
