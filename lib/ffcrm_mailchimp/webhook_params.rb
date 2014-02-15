#
# Turns mailchimp webhook paramaters into a proxy class ready that can manage its own state.
# Usage: FfcrmMailchimp::WebhookParams.new( params )

require 'ostruct'
require 'active_support/core_ext/object'

module FfcrmMailchimp
  class WebhookParams < OpenStruct

    # 'type' is also defined

    def email
      data[:email]
    end

    def merges_email
      data[:merges][:EMAIL]
    end

    def old_email
      data[:email]
    end

    def new_email
      data[:new_email]
    end

    def list_id
      data[:list_id]
    end

    def interests
      data[:merges][:INTERESTS]
    end

    def groupings
      data[:merges][:GROUPINGS]
    end

    def first_name
      data[:merges][:FNAME]
    end

    def last_name
      data[:merges][:LNAME]
    end

    #
    # Outputs into a form suitable for saving on the custom_field
    # E.g. ["1525_group1", "1525_group2", "list_1235432", "source_webhook"]
    def attributes
      list = "list_#{list_id}"
      source = "source_webhook"
      group_id = groupings["0"]["id"]
      groups = []
      if interests.present?
        group = groupings["0"]["groups"].split(",").collect(&:strip).map{ |name| "#{group_id}_#{name}" }
        groups << group
      end
      return (groups << [list] << source).flatten
    end

  end
end
