#
# A list subscription encapsulates a specific instance of a contact and
# the list he/she is subscribed too. It is useful for serializing individual
# subscription data to be stored on the contact object itself.

require 'ostruct'
require 'active_support/core_ext/object'

module FfcrmMailchimp
  class ListSubscription < OpenStruct

    #
    # Create a ListSubscription from a hash
    # E.g. {"list_id"   => "1235432",
    #       "source"    => "webhook",
    #       "groupings" => [{"id" => "1525", "groups" => ["group1","group2"]},
    #                       {"id" => "1243", "groups" => ["group3","group4"]} ]}

    def source_is_ffcrm?
      source == 'ffcrm'
    end

    def has_list?
      list_id.present?
    end

    def has_groupings?
      groupings.present?
    end

    #
    # Do we have all the information necessary to subscribe to the list?
    def wants_to_subscribe?
     source_is_ffcrm? && has_list?
    end

    #
    # Does a specific group name exist in this subscription
    def has_group?(name)
      (groupings || []).select{ |grouping| grouping['groups'].include?(name) }.any?
    end

    #
    # Create a ListSubscription from form data
    # {"list_id"=>"9285aa3b18", "groups"=>{"8661"=>["Option 1", ""], "8669"=>["Option 3", ""]}, "source"=>"ffcrm"}
    # becomes
    # E.g.data   {"list_id"   => "1235432",
    #             "source"    => "webhook",
    #             "groupings" => [{"id" => "1525", "groups" => ["group1","group2"]},
    #                             {"id" => "1243", "groups" => ["group3","group4"]}] }
    def self.from_form(params)
      groupings = []
      if (groups = params['groups']).present?
        groups.each do |id, value|
          groupings << { "id" => id, "groups" => value.reject(&:blank?) }
        end
      end
      data = { "list_id" => params['list_id'], "source" => params['source'], "groupings" => groupings }
      ListSubscription.new( data )
    end

  end
end
