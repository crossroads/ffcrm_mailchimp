require 'ffcrm_mailchimp/webhook_params'

module FfcrmMailchimp

  #
  # Receive incoming mailchimp webhooks and update FFCRM
  class InboundSync

    attr_accessor :data

    #
    # Usage: FfcrmMailchimp::InboundSync.process(params)
    def self.process(params)
      new(params).process
    end

    #
    # Process the webhook and apply changes to CRM contacts
    def process
      return unless list_field_exists?
      case data.type
      when "subscribe"
        subscribe
      when "profile"
        profile_update
      when "upemail"
        email_changed
      when "unsubscribe"
        unsubscribe
      else
      end
    end

    private

    def initialize(params)
      @data = FfcrmMailchimp::WebhookParams.new(params)
    end

    #
    # Subscribe the user to the mailing list and create one if they don't exist
    def subscribe
      contact = Contact.find_by_email( data.email ) || Contact.new( email: data.merges_email )
      contact.first_name = data.first_name
      contact.last_name = data.last_name
      contact.send("#{custom_field.name}=", data.attributes)
      contact.save
    end

    #
    # Update the name and list preferences for a particular contact
    def profile_update
      contact = Contact.find_by_email( data.email )
      if contact.present?
        contact.first_name = data.first_name
        contact.last_name = data.last_name
        contact.send("#{custom_field.name}=", data.attributes)
        contact.save
      end
    end

    #
    # If no user with 'new_email' exists, then update the email address.
    # If another user exists with 'new_email' then remove the current subscription.
    #   because a profile_update will be fired shortly which will update the new profile subscriptions.
    def email_changed
      return if data.new_email.blank? or data.old_email.blank?
      old_contact = Contact.find_by_email( data.old_email )
      new_contact = Contact.find_by_email( data.new_email )
      return if !old_contact.present?
      if !new_contact.present?
        old_contact.update_attributes(email: data.new_email)
      else
        old_contact.update_attributes( custom_field.name => [] )
      end

    end

    #
    # Unsubscribe the user
    def unsubscribe
      contact = Contact.find_by_email( data.email )
      if contact.present?
        contact.update_attributes( custom_field.name => [] )
      end
    end

    #
    # Use the webhook's list_id parameter to lookup the custom_field we should update
    def custom_field
      @cf ||= Field.where( as: 'mailchimp_list' ).select{ |f| f.settings['list_id'] == data.list_id }.first
    end

    #
    # Ensure that a custom field related to the webhook list_id exists.
    # If not, then we're probably not interested in this webhook.
    def list_field_exists?
      !!custom_field
    end

  end

end
