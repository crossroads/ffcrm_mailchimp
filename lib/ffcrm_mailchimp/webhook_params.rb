#
# Enscapuslate Mailchimp webhook parameters

require 'ostruct'
require 'ffcrm_mailchimp/list_subscription'

module FfcrmMailchimp
  class WebhookParams < OpenStruct

    # 'type' is also defined

    def email
      data['email']
    end

    def merges_email
      data['merges']['EMAIL']
    end

    def old_email
      data['old_email']
    end

    def new_email
      data['new_email']
    end

    def list_id
      data['list_id']
    end

    def groupings
      data['merges']['GROUPINGS']
    end

    def first_name
      data['merges']['FNAME']
    end

    def last_name
      data['merges']['LNAME']
    end

    def data
      (super || {}).with_indifferent_access # this is deep so affects data['merges'] too
    end

    #GROUPINGS: {"0"=>
    #              {"id"=>"5641",
    #               "name"=>"Group One",
    #               "groups"=>"Option 1, Option 2"
    #              },
    #            "1"=>
    #              {"id"=>"8669",
    #               "name"=>"Group Two",
    #               "groups"=>"Option 3, Option 4"
    #              }  }
    def to_list_subscription
      groups = []
      groupings.map do |key, value|
        groups << { 'id' => value['id'], 'groups' => value['groups'].split(', ').map(&:strip) }
      end
      ListSubscription.new( 'list_id' => list_id, 'source' => 'webhook', 'groupings' => groups )
    end

  end
end
