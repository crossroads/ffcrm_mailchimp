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
      if config.sync_disabled?
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::InboundSync Sync disabled. Ignoring incoming #{data.type}")
        return
      end
      case data.type
      when "subscribe"
        subscribe
      when "profile"
        profile_update
      when "upemail"
        email_changed
      when "unsubscribe"
        unsubscribe
      when "cleaned"
        clean
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
      c = contact || Contact.new( email: data.merges_email )
      c.first_name = data.first_name
      c.last_name = data.last_name
      c.send("#{custom_field.name}=", cf_attributes_for(data) )
      c.phone = data.phone if config.track_phone and !data.phone.blank? # update phone if one is provided
      c.addresses << data.address if config.track_address and data.has_address? # update address if one is provided
      c.send("#{config.consent_field_name}=", data.consent) if config.track_consent and data.consent.present? # update consent field if one is provided
      c.tag_list = (c.tag_list << list_tag.name).join(',') if list_tag.present? # If list belongs to a field_group with a tag, ensure the tag is present on the contact so the fields are visible.
      c.save
    end

    #
    # Update the name and list preferences for a particular contact
    def profile_update
      if contact.present?
        contact.first_name = data.first_name
        contact.last_name = data.last_name
        contact.send("#{custom_field.name}=", cf_attributes_for(data))
        contact.phone = data.phone if config.track_phone and !data.phone.blank? # update phone if one is provided
        contact.send("#{config.address_type.downcase}_address=", data.address) if config.track_address and data.has_address? # update address if one is provided
        contact.send("#{config.consent_field_name}=", data.consent) if config.track_consent and data.consent.present? # update consent field if one is provided
        contact.tag_list = (contact.tag_list << list_tag.name).join(',') if list_tag.present? # If list belongs to a field_group with a tag, ensure the tag is present on the contact so the fields are visible.
        contact.save
      else
        subscribe
      end
    end

    #
    # If no user with 'new_email' exists, then update the email address.
    # If another user exists with 'new_email' then remove the current subscription.
    #   because a profile_update will be fired shortly which will update the new profile subscriptions.
    def email_changed
      return if data.new_email.blank? or data.old_email.blank?
      old_contact = Contact.where(email: data.old_email).order(:id).first
      new_contact = Contact.where(email: data.new_email).order(:id).first
      return if !old_contact.present?
      if !new_contact.present?
        old_contact.update( email: data.new_email )
      else
        old_contact.update( custom_field.name => {} )
      end
    end

    #
    # Unsubscribe the user
    def unsubscribe
      if contact.present?
        contact.update( custom_field.name => {} )
      end
    end

    #
    # Clean a user off a particular list
    def clean
      unsubscribe
      if (user_id = config.user_id) and contact.present?
        contact.comments.create!( user_id: user_id, comment: clean_reason )
        contact.update(:subscribed_users, contact.subscribed_users - [user_id]) # don't subscribe Mailchimp user to email updates
      end
    end

    def clean_reason
      case data.reason
      when 'hard'
        "Mailchimp has automatically cleaned #{data.email} from the #{custom_field.label} list because of a hard bounce."
      when 'abuse'
        "Mailchimp has automatically cleaned #{data.email} from the #{custom_field.label} list because of an abuse report."
      else
        "Mailchimp has automatically cleaned #{data.email} from the #{custom_field.label} list (reason given: #{data.reason})"
      end
    end

    #
    # Use the webhook's list_id parameter to lookup the custom_field we should update
    def custom_field
      @cf ||= config.mailchimp_list_fields.select{ |f| f.settings['list_id'] == data.list_id }.first
    end

    #
    # Ensure that a custom field related to the webhook list_id exists.
    # If not, then we're probably not interested in this webhook.
    def list_field_exists?
      data.list_id.present? and !!custom_field
    end

    #
    # Return the field_group tag that the list belongs to, if any
    def list_tag
      custom_field.field_group.tag
    end

    def config
      FfcrmMailchimp.config
    end

    # Serializes WebhookParams into ListSubscription ready for saving on custom field
    # Returns Hash
    def cf_attributes_for(data)
      (data.to_list_subscription || {}).to_h
    end

    def contact
      @contact ||= Contact.where(email: data.email).order(:id).first
    end

  end

end
