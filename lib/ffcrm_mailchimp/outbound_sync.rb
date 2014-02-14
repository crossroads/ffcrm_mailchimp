require 'ffcrm_mailchimp/config'

module FfcrmMailchimp

  #
  # Process contact updates from FFCRM to Mailchimp
  class OutboundSync

    attr_accessor :record

    #
    # Usage: FfcrmMailchimp::OutboundSync.subscribe(record)
    def self.subscribe(record)
      new(record).subscribe
    end

    #
    # Usage: FfcrmMailchimp::OutboundSync.unsubscribe(record)
    def self.unsubscribe(record)
      new(record).unsubscribe
    end

    def initialize(record)
      @record = record
    end

    #
    # Iterate over each list that has changed and update mailchimp subscriptions
    # Also handles unsubscribes as necessary
    def subscribe
      if email_changed? or list_subscriptions_changed.any?
        list_subscriptions_changed.each do |column|
          subscription = ListSubscription.from_array( @record.send(column) )
          if subscription.wants_to_subscribe? # handles subscription updates too
            apply_mailchimp_subscription(subscription)
          else
            list_id = list_id_from_column(column) # list_id isn't in ListSubscription any more
            unsubscribe_from_mailchimp_list(list_id)
          end
        end
        Rails.logger.info("FfcrmMailchimp: subscriptions updated for contact #{@record.id}")
      end
    end

    #
    # When a contact is deleted, remove all mailchimp subscriptions
    def unsubscribe
      ffcrm_list_ids.each do |list_id|
        unsubscribe_from_mailchimp_list(list_id)
      end
    end


    private

    #
    # Changes to the email address on the record
    # Either nil or a before/after array ['test@example.com', 'testing@example.com']
    # Depends on ActiveRecord::Dirty
    def email_changed?
      @record.email_change.present?
    end

    #
    # Changes to the list subscriptions on the record
    # Returns an array of 'mailchimp_list' custom fields that have changed in the update
    # Depends on ActiveRecord::Dirty
    def list_subscriptions_changed
      fields = []
      changes = Field.where(as: 'mailchimp_list').collect do |field|
        fields << field.name if @record.send("#{field.name}_changed?")
      end
      return fields
    end

    #
    # Is the user already subscribed in Mailchimp?
    def is_subscribed_mailchimp_user?(list_id)
      api_query = gibbon.lists.member_info({ id: list_id, emails: [{ email: email }] })
      api_query["error_count"].zero? && api_query["data"].first["status"] == "subscribed"
    end

    #
    # If the user is not currently subscribed to this mailchimp list, subscribe them.
    # If the user is currently subscribed to this mailchimp list, update their interest group settings
    def apply_mailchimp_subscription(subscription)
      list_id = subscription.list_id
      group_id = subscription.group_id
      groups = subscription.groups
      if !is_subscribed_mailchimp_user?(list_id)
        gibbon.lists.subscribe({:id => list_id, :email => {:email => email},
        :merge_vars => {:FNAME => @record.first_name, :LNAME => @record.last_name,
          groupings: [{id: group_id, groups: groups }]}, :double_optin => false})
      else
        gibbon.lists.subscribe({:id => list_id, :email => {:email => email},
        :merge_vars => {:FNAME => @record.first_name, :LNAME => @record.last_name,
          groupings: [{id: group_id, groups: groups }]}, :update_existing => "true", :double_optin => false})
      end
    end

    #
    # Unsubscribe a user from a particular mailchimp list
    def unsubscribe_from_mailchimp_list(list_id)
      if is_subscribed_mailchimp_user?(list_id)
        gibbon.lists.unsubscribe( id: list_id, email: { email: email, delete_member: false, send_notify: false } )
      end
    end

    #
    # The monkey that does the actual api calls
    def gibbon
      @gibbon ||= Config.new.mailchimp_api
    end

    #
    # The email address used for mailchimp subscriptions.
    # Defaults to the primary email address of the contact
    def email
      @record.email
    end

    #
    # Find all list_ids configured in FFCRM
    def ffcrm_list_ids
      Field.where(as: 'mailchimp_list').map{ |f| f.settings['list_id'] }
    end

    #
    # Determine the list id from the field configuration
    def list_id_from_column(column)
       Field.where(name: column).first.settings[:list_id]
    end

  end
end
