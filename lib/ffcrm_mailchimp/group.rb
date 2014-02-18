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
      self.all_groups(list_id).select{ |group| group.list_id == list_id }
    end

    private

    # Ask the Mailchimp API for all available groups for a give list_id
    # Return a hash of groups with the group details and list id
    # NOTE: we only support the first group for now
    def self.all_groups(list_id)
      data = groups_from_mailchimp(list_id).first
      groups = data["groups"]
      groups.map(&:stringify_keys).map {|grp| new("#{data["id"]}_"+grp["name"],
        grp["name"], list_id)}
    end

    # Get the groups from mailchimp via our caching wrapper
    def self.groups_from_mailchimp(list_id)
      CacheMonkey.groups(list_id)
    end
  end

end
