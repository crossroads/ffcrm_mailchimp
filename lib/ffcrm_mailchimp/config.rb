require 'gibbon'

module FfcrmMailchimp

  class Config

    attr_accessor :config

    def initialize
      @config = Setting.ffcrm_mailchimp
    end

    #
    # Used in the admin section to apply settings
    def update!(options)
      @config = Setting.ffcrm_mailchimp = {
        sync_disabled: options[:sync_disabled],
        api_key: options[:api_key],
        user_id: options[:user_id],
        verbose: options[:verbose],
        subgroups_only: options[:subgroups_only],
        track_phone: options[:track_phone],
        track_address: options[:track_address],
        address_type: options[:address_type],
        track_consent: options[:track_consent],
        consent_field_name: options[:consent_field_name],
      }
    end

    #
    # A deadman switch to turn off the sync temporarily if needed.
    def sync_disabled
      config.present? ? config[:sync_disabled] == 'true' : false
    end

    def sync_disabled?
      sync_disabled
    end

    def sync_enabled?
      !sync_disabled?
    end

    #
    # The api key is used to connect to Mailchimp accounts.
    def api_key
      config.present? ? config[:api_key] : nil
    end

    def mailchimp_api
      Gibbon::API.new(api_key)
    end

    # the id of a CRM user that will be the 'mailchimp' user in Papertrail
    def user_id
      config.present? ? config[:user_id] : nil
    end

    def verbose
      config.present? ? config[:verbose] == 'true' : false
    end

    # Do we want to enable subscriptions to the list without a subgroup?
    def subgroups_only
      config.present? ? config[:subgroups_only] == 'true' : false
    end

    def subgroups_only?
      subgroups_only
    end

    # Are we tracking phone?
    def track_phone
      config.present? ? config[:track_phone] == 'true' : false
    end

    # Are we tracking address?
    def track_address
      config.present? ? config[:track_address] == 'true' : false
    end

    # If creating an address, sets the default type to create as
    def address_type
      config.present? ? config[:address_type] : 'Home'
    end

    # Are we tracking the CONSENT merge tag?
    def track_consent
      config.present? ? config[:track_consent] == 'true' : false
    end

    # If there is a custom direct marketting consent field, enable it to be selected
    # otherwise, assume it's fat_free_crm's do_not_call field.
    def consent_field_name
      config.present? ? config[:consent_field_name] : 'do_not_call'
    end

    #
    # Returns all the mailchimp_list fields
    def mailchimp_list_fields
      Field.where(as: 'mailchimp_list')
    end

  end

end
