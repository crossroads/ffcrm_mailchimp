require 'ostruct'
require 'ffcrm_mailchimp/list'

module FfcrmMailchimp

  # This relates to a group inside a list in Mailchimp
  # It's not meant to be called directly, rather via groups_for inside a List
  class Group < OpenStruct

    # {"id"=>8661,
    #  "list_id"=>7531,
    #  "title"=>"Group One",
    #  "groups"=>
    #    [{"id"=>"1", "name"=>"Option 1"},
    #     {"id"=>"2", "name"=>"Option 2"}]}
    #
    # We also inject 'list_id' when creating a new group instance

    # Returns ["Option 1", "Option 2"]
    def group_names
      groups.collect{ |group| group.stringify_keys['name'] }
    end

    # Return all the groups that belong to a particular list in Mailchimp
    def self.groups_for(list_id)
      return [] if list_id.nil?
      FfcrmMailchimp::Api.interest_groupings(list_id).map do |group|
        new( group.merge( list_id: list_id ) )
      end
    end

  end

end
