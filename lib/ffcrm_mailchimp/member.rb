require 'ostruct'
require 'gibbon'
require 'json'
require 'ffcrm_mailchimp/config'
require 'ffcrm_mailchimp/list'
require 'ffcrm_mailchimp/webhook_params'

module FfcrmMailchimp

  # This enscapsulates the result of calling lists on the Mailchimp Export API
  # which provides member subscription information for a list
  class Member < OpenStruct

    # email
    # first name
    # last name
    # list_id
    # subscribed_groups: {'Group One' => "Option 1, Option 2", "Group Two" => "Option 3" }
    # last_changed

    # Converts {'Group One' => "Option 1, Option 2", "Group Two" => "Option 3" }
    # into
    # {"0"=>
    #   {"id"=>"5641",
    #    "name"=>"Group One",
    #    "groups"=>"Option 1, Option 2"
    #   },
    #  "1"=>
    #    {"id"=>"8669",
    #     "name"=>"Group Two",
    #     "groups"=>"Option 3, Option 4"
    #    }
    # }
    def groupings
      @groupings = {}
      subscribed_groups.each_with_index do |group, index|
        name, groups = group
        id = find_group_by_name(name).try(:id)
        grouping = { 'id' => "#{id}", 'name' => name, 'groups' => groups }
        @groupings.merge!( "#{index}" => grouping )
      end
      @groupings
    end

    # serialize this into a WebhookParams object so we can pass to InboundSync
    def to_webhook_params
      merges = { 'FNAME' => first_name, 'LNAME' => last_name, 'GROUPINGS' => groupings }
      data = { 'email' => email, 'merges' => merges, 'list_id' => list_id }
      FfcrmMailchimp::WebhookParams.new( 'data' => data )
    end

    private

    # Lookup a group by its name.
    def find_group_by_name(name)
      list = FfcrmMailchimp::List.find(list_id)
      list.groups.select{ |group| group.name == name }.first
    end

  end

end
