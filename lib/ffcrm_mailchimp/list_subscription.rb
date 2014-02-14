#
# A list subscription is serialised to yaml and stored on the contact object itself.

require 'ostruct'
require 'active_support/core_ext/object'

module FfcrmMailchimp
  class ListSubscription < OpenStruct
    # methods :source, :list_id, :groupings

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
     source_is_ffcrm? && (has_list? || has_groupings?)
    end

    #
    # Extract the group_id from groupings
    def group_id
      ( groupings || [{}] ).first["group_id"]
    end

    #
    # Extract the groups from groupings
    def groups
      ( groupings || [{}] ).first["groups"]
    end

    #
    # Serialize into array format for storing in ActiveRecord objects.
    # TODO
    def to_a
      [{ "list_id"   => list_id,
         "source"    => source,
         "groupings" => groupings
      }]
    end

    #
    # Create a ListSubscription from a stored array
    # E.g.data  [{"list_id"   => "1235432",
    #             "source"    => "webhook",
    #             "groupings" => [{"group_id" => "1525", "groups"=>["group1","group2"]}]}]
    def self.from_array(data)
      ListSubscription.new( data.first )
    end

  end
end
