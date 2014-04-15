require 'ffcrm_mailchimp/list_subscription'

module FfcrmMailchimp

  #
  # Process contact updates from FFCRM to Mailchimp
  class OutboundSync

    attr_accessor :record, :changes

    def initialize(record, changes)
      @record = record
      @changes = changes
    end

    #
    # Update mailchimp subscription for all the mailchimp lists linked in CRM
    # Handles unsubscribes when necessary
    def subscribe
      if subscribed_email.blank?
        FfcrmMailchimp.logger("OutboundSync: no email address for #{@record.class}##{@record.id}. Cannot proceed.")
        return
      end
      mailchimp_list_field_names.each do |column|
        subscription = ListSubscription.new( @record.send(column) )
        if !subscription.source_is_ffcrm? # Stop if this is a webhook from mailchimp
          FfcrmMailchimp.logger("OutboundSync: ignoring updates to #{@record.class}##{@record.id} (change initiated by webhook or no list subscription data)")
          break
        end
        # Note: it's important to get list_id from the column not the ListSubscription
        # because if list_id is missing in ListSubscription then that means 'unsubscribe' from list
        list_id = list_id_from_column(column)
        if subscription.wants_to_subscribe? and !@record.email.blank?
          apply_mailchimp_subscription(subscription, list_id)
        else
          # list is no longer selected on form or @record.email is blank
          unsubscribe_from_mailchimp_list(list_id)
        end
      end
    end

    def self.unsubscribe(email)
      new(nil, nil).unsubscribe(email)
    end

    #
    # When a contact is deleted, remove all mailchimp subscriptions
    def unsubscribe(email)
      if email.blank? # we can't do anything without an email address
        FfcrmMailchimp.logger("OutboundSync: cannot unsubscribe contact without an email address")
      else
        FfcrmMailchimp.logger("OutboundSync: unsubscribing #{email} from all mailchimp lists.")
        ffcrm_list_ids.each do |list_id|
          unsubscribe_from_mailchimp_list(list_id, email)
        end
      end
    end



    private

    #
    # Is the user already subscribed in Mailchimp?
    def is_subscribed_mailchimp_user?(list_id, email = subscribed_email)
      api_query = gibbon.lists.member_info({ id: list_id, emails: [{ email: email }] })
      result = api_query["error_count"].zero? && api_query["data"].first["status"] == "subscribed"
      FfcrmMailchimp.logger("OutboundSync: #{email} is #{result ? 'subscribed' : 'not subscribed'} on list #{list_id}. Reply: #{api_query}")
      result
    end

    #
    # If the user is not currently subscribed to this mailchimp list, subscribe them.
    # If the user is currently subscribed to this mailchimp list, update their interest group settings
    def apply_mailchimp_subscription(subscription, list_id)
      new_email = @record.email
      return if new_email.blank?
      params = { id: list_id, email: { email: subscribed_email }, double_optin: false,
                 merge_vars: { FNAME: @record.first_name, LNAME: @record.last_name, groupings: subscription.groupings } }
      params[:merge_vars].merge!( extra_merge_vars )
      params[:merge_vars].merge!('new-email' => new_email) if subscribed_email != new_email
      if is_subscribed_mailchimp_user?(list_id)
        params.merge!( update_existing: "true" )
        FfcrmMailchimp.logger("OutboundSync: updating subscription for contact #{@record.id} on list #{list_id} using following params #{params}")
      else
        FfcrmMailchimp.logger("OutboundSync subscribing contact #{@record.id} to list #{list_id} using following params #{params}")
      end
      gibbon.lists.subscribe(params)
    end

    #
    # Unsubscribe a user from a particular mailchimp list
    # Note: delete_member is true, this means the person is completely deleted
    # from the list rather than being unsubscribed - they can't be re-added by us
    # if they are unsubscribed.
    def unsubscribe_from_mailchimp_list(list_id, email = subscribed_email)
      if is_subscribed_mailchimp_user?(list_id, email)
        params = { id: list_id, email: { email: email, delete_member: true, send_notify: false } }
        FfcrmMailchimp.logger("OutboundSync: unsubscribing #{email} from list #{list_id} using following params: #{params}")
        gibbon.lists.unsubscribe( params )
      else
        FfcrmMailchimp.logger("OutboundSync: cannot unsubscribe contact as #{email} is not subscribed to the list #{list_id}")
      end
    end

    #
    # Return email address currently registered on the mailchimp list
    # If this is blank, we can't do anything
    def subscribed_email
      !@changes.old_email.blank? ? @changes.old_email : @record.email
    end

    #
    # The monkey that does the actual api calls
    def gibbon
      @gibbon ||= config.mailchimp_api
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
                             'CITY' => address.city, 'STATE' => address.state, 'ZIP' => address.zipcode,
                             'COUNTRY' => Hash[ActionView::Helpers::FormOptionsHelper::COUNTRIES].invert[address.country] )
        end
      end
      if FfcrmMailchimp.config.track_phone
        merge_vars['PHONE'] = @record.phone
      end
      if FfcrmMailchimp.config.track_consent
        consent_field_name = FfcrmMailchimp.config.consent_field_name
        if @record.attributes.keys.include?(consent_field_name)
          merge_vars['CONSENT'] = @record.send(consent_field_name) # should be 'Yes' or 'No'
        end
      end
      merge_vars
    end

  end
end
