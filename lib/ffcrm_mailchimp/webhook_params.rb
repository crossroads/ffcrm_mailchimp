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
      data['merges']['ZIP']
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

  end
end
