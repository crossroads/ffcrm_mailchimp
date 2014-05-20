require 'ffcrm_mailchimp'

module FfcrmMailchimp

  #
  # Helps us find the changes that we're interested in sync'ing to Mailchimp
  class Changes
    attr_accessor :email_change, :list_columns_changed, :first_name_change, :last_name_change, :phone_change, :address_change, :consent_change

    def initialize(record)
      @email_change = record.email_change
      @first_name_change = record.first_name_change
      @last_name_change = record.last_name_change
      @list_columns_changed =
        FfcrmMailchimp.config.mailchimp_list_fields.map do |field|
          record.send("#{field.name}_changed?") ? field.name : nil
        end.compact
      @phone_change = record.phone_change
      #@address_change = record.address_change
      @consent_change = record.send("#{config.consent_field_name}_change")
    end

    #
    # Analyse the changes that have taken place and decide if we need to tell mailchimp
    def need_sychronization?
      # we need to disable this now because of a case when merging a contact:
      # the slave record is deleted and the email subsequently removed from the list
      # if the master record doesn't alter the mailing lists then need_synchronization? returns false
      # Thus the email is removed from mailchimp and NOT re-added. CRM records it as on the list but mailchimp doesn't
      #email_changed? or name_changed? or list_columns_changed? or phone_changed? or consent_changed?
      true
    end

    # Changes to the email address on the record
    # Either nil or a before/after array ['test@example.com', 'testing@example.com']
    def old_email
      (@email_change || []).first
    end

    def new_email
      (@email_change || []).last
    end

    def email_changed?
      @email_change.present?
    end

    def name_changed?
      @first_name_change.present? or @last_name_change.present?
    end

    def list_columns_changed?
      @list_columns_changed.any?
    end

    def phone_changed?
      config.track_phone and @phone_change.present?
    end

    def consent_changed?
      config.track_consent and @consent_change.present?
    end

    def config
      FfcrmMailchimp.config
    end

  end

end
