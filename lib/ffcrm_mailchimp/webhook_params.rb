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
      data['merges']['FIRST_NAME']
    end

    def last_name
      data['merges']['LAST_NAME']
    end

    def phone
      data['merges']['PHONE']
    end

    def street1
      data['merges']['STREET1']
    end

    def street2
      data['merges']['STREET2']
    end

    def city
      data['merges']['CITY']
    end

    def state
      data['merges']['STATE']
    end

    def zipcode
      data['merges']['ZIPCODE']
    end

    def country
      data['merges']['COUNTRY']
    end

    def consent
      data['merges']['CONSENT']
    end

    # E.g. Zambia => "ZM"
    def country_code
      Hash[ActionView::Helpers::FormOptionsHelper::COUNTRIES][country]
    end

    def address
      address_type = FfcrmMailchimp.config.address_type
      Address.new(address_type: address_type, street1: street1, street2: street2, city: city, state: state, zipcode: zipcode, country: country_code)
    end

    # how to we know if we have sufficient data for a real address
    def has_address?
      street1.present? and city.present? and country.present?
    end

    def reason
      data['reason']
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

    #
    # Creates a new WebhookParams object from a Mailchimp API list member response
    # api_member_hash =
    #   { "email_address": "test@example.com",
    #     "list_id" : "3d532d43",
    #     "status": "subscribed",
    #     "merge_fields": {
    #       "FIRST_NAME": "Jeremy",
    #       "LAST_NAME": "Nullson"
    #     },
    #     "interests": {
    #       "70b7107c8a": true,
    #       "7c1719c788": false,
    #       "8d856390f6": true,
    #     }
    #   }
    # )
    # currently doesn't handle address or phone
    def self.new_from_api(api_member_hash)
      list_id = api_member_hash['list_id']
      merges = {
        'EMAIL' => api_member_hash['email_address'],
        'FIRST_NAME' => api_member_hash['merge_fields']['FIRST_NAME'],
        'LAST_NAME' => api_member_hash['merge_fields']['LAST_NAME'],
        'GROUPINGS' => convert_interest_groups(list_id, api_member_hash['interests'])
      }
      data = {
        'email' => api_member_hash['email_address'],
        'list_id' => list_id,
        'consent' => api_member_hash['merge_fields']['CONSENT'],
        'merges' => merges
      }
      new( 'data' => data )
    end

    private

    # Converts "interests"=>{"70b7107c8a"=>true, "7c1719c788"=>false, "8d856390f6"=>true ...}
    # into
    # {"0"=>
    #   {"id"=>"5641",
    #    "name"=>"Group One",
    #    "groups"=>"Option 1, Option 3"
    #   },
    #  "1"=>
    #    {"id"=>"8669",
    #     "name"=>"Group Two",
    #     "groups"=>"Option 3, Option 4"
    #    }
    # }
    def self.convert_interest_groups(list_id, subscribed_interest_groups)
      subscribed_interest_group_ids = (subscribed_interest_groups || {}).select{ |interest_id, value| value }.keys
      interest_subscriptions = []
      FfcrmMailchimp::Api.interest_groupings(list_id).each do |grouping|
        group_names = grouping['groups'].select{|x| subscribed_interest_group_ids.include?(x['id'])}.map{|x| x["name"]}
        interest_subscriptions << ( {"id" => grouping['id'], "name" => grouping["title"], "groups" => group_names.join(", ")} ) if group_names.any?
      end
      result = {}
      interest_subscriptions.each_with_index do |interest_category, index|
        result[index.to_s] = interest_category
      end
      result
    end

  end
end
