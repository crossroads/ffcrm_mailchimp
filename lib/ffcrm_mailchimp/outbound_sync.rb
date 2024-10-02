require 'ffcrm_mailchimp/list_subscription'
require 'ffcrm_mailchimp/api'

module FfcrmMailchimp

  #
  # Process contact updates from FFCRM to Mailchimp
  class OutboundSync

    attr_accessor :record, :changes

    def initialize(record, subscribed_email)
      @record = record
      @subscribed_email = subscribed_email
    end

    #
    # Update mailchimp subscription for all the mailchimp lists linked in CRM
    # Handles unsubscribes when necessary
    def subscribe
      if @subscribed_email.blank?
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::OutboundSync: no email address for #{@record.class}##{@record.id}. Cannot proceed.")
        return
      end
      mailchimp_list_field_names.each do |column|
        subscription = ListSubscription.new( @record.send(column) )
        if !subscription.source_is_ffcrm? # Stop if this is a webhook from mailchimp
          FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::OutboundSync: ignoring updates to #{@record.class}##{@record.id} (change initiated by webhook or no list subscription data)")
          break
        end
        # Note: it's important to get list_id from the column not the ListSubscription
        # because if list_id is missing in ListSubscription then that means 'unsubscribe' from list
        list_id = list_id_from_column(column)
        if subscription.wants_to_subscribe? and !@record.email.blank?
          apply_mailchimp_subscription(subscription, list_id)
        else
          # list is no longer selected on form or @record.email is blank
          FfcrmMailchimp::Api.unsubscribe(list_id, @subscribed_email)
        end
      end
    end

    def self.unsubscribe(email)
      new(nil, nil).unsubscribe(email)
    end

    #
    # When a contact is deleted, remove all mailchimp subscriptions
    def unsubscribe(email)
      if email.present?
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::OutboundSync: unsubscribing #{email} from all mailchimp lists.")
        ffcrm_list_ids.each do |list_id|
          FfcrmMailchimp::Api.unsubscribe(list_id, email)
        end
      end
    end

    private

    #
    # If the user is not currently subscribed to this mailchimp list, subscribe them.
    # If the user is currently subscribed to this mailchimp list, update their interest group settings
    def apply_mailchimp_subscription(subscription, list_id)
      email = @record.email
      return if email.blank?
      merge_fields = { FIRST_NAME: @record.first_name, LAST_NAME: @record.last_name }.merge(extra_merge_vars)
      body = { email_address: email, merge_fields: merge_fields }
      FfcrmMailchimp::Api.subscribe(list_id, @subscribed_email, body, subscription.groupings)
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

    #
    # All the mailchimp_list field names that are registered
    def mailchimp_list_field_names
      config.mailchimp_list_fields.map(&:name)
    end

    def config
      FfcrmMailchimp.config
    end

    #
    # Returns a hash of address, phone, and consent merge vars for updating mailchimp
    def extra_merge_vars
      merge_vars = {}
      if FfcrmMailchimp.config.track_address
        address_type = FfcrmMailchimp.config.address_type
        address = @record.addresses.where(address_type: address_type).first
        if address.present?
          merge_vars.merge!( 'STREET1' => address.street1, 'STREET2' => address.street2,
                             'CITY' => address.city, 'STATE' => address.state, 'ZIPCODE' => address.zipcode,
                             'COUNTRY' => Hash[ActionView::Helpers::FormOptionsHelper::COUNTRIES].invert[address.country] )
        end
      end
      if FfcrmMailchimp.config.track_phone
        merge_vars['PHONE'] = @record.phone
      end
      if FfcrmMailchimp.config.track_consent
        consent_field_name = FfcrmMailchimp.config.consent_field_name
        if @record.attributes.keys.include?(consent_field_name)
          value = @record.send(consent_field_name)
          # handle FFCRM default 'do_not_call' which is the reverse of 'consent'
          if (consent_field_name == 'do_not_call')
            value = (value ? 'No' : 'Yes')
          else
            value = (value.downcase == 'yes' || value == true) ? 'Yes' : 'No'
          end
          merge_vars['CONSENT'] = value # should be 'Yes' or 'No'
        end
      end
      merge_vars
    end

  end
end
