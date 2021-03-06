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
    # first_name
    # last_name
    # phone
    # street1
    # street2
    # city
    # state
    # zipcode
    # country
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

    #
    # Returns a flattened array of all the groups
    # Converts {'Group One' => "Option 1, Option 2", "Group Two" => "Option 3" }
    # into ["Option 1", "Option 2", "Option 3"]
    def groups
      groupings.map{ |key, value| value['groups'] }.collect{|x| x.split(", ")}.flatten.compact
    end

    # serialize this into a WebhookParams object so we can pass to InboundSync
    def to_webhook_params
      merges = { 'FIRST_NAME' => first_name, 'LAST_NAME' => last_name, 'GROUPINGS' => groupings, 'EMAIL' => email }
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
