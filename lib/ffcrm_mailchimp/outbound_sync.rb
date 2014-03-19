require 'ffcrm_mailchimp/list_subscription'

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
          subscription = ListSubscription.new( @record.send(column) )
          break if !subscription.source_is_ffcrm?
          # It's important to get list_id from the column not the ListSubscription
          # because if list_id is missing in ListSubscription then that mean 'unsubscribe' from list
          list_id = list_id_from_column(column)
          if subscription.wants_to_subscribe? # handles updates too
            apply_mailchimp_subscription(subscription, list_id)
          else
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
      changes = config.mailchimp_list_fields.collect do |field|
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
    def apply_mailchimp_subscription(subscription, list_id)
      params = { id: list_id, email: { email: @record.email}, double_optin: false,
                merge_vars: { FNAME: @record.first_name, LNAME: @record.last_name, groupings: subscription.groupings } }
      params.merge!( update_existing: "true" ) if is_subscribed_mailchimp_user?(list_id)
      gibbon.lists.subscribe(params)
    end

    #
    # Unsubscribe a user from a particular mailchimp list
    # Note: delete_member is true, this means the person is completely deleted
    # from the list rather than being unsubscribed - they can't be re-added by us
    # if they are unsubscribed.
    def unsubscribe_from_mailchimp_list(list_id)
      return unless email.present?
      if is_subscribed_mailchimp_user?(list_id)
        gibbon.lists.unsubscribe( id: list_id, email: { email: email, delete_member: true, send_notify: false } )
      end
    end

    #
    # The monkey that does the actual api calls
    def gibbon
      @gibbon ||= config.mailchimp_api
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
      config.mailchimp_list_fields.map{ |f| f.settings['list_id'] }
    end

    #
    # Determine the list id from the field configuration
    def list_id_from_column(column)
       Field.where(name: column).first.settings[:list_id]
    end

    def config
      FfcrmMailchimp.config
    end

  end
end
