require 'ffcrm_mailchimp/config'
require 'ffcrm_mailchimp/list_subscription'

module FfcrmMailchimp

  #
  # Given a Mailchimp list @member and it's corresponding FFCRM @contact,
  # discover any differences between them.
  class Comparision

    attr_accessor :member, :contact
    # first_name, last_name, groups
    # phone, address, consent

    def initialize(member, contact)
      @member = member
      @contact = contact
    end

    def id
      contact.try(:id)
    end

    def contact_email
      contact.try(:email)
    end

    def member_email
      member.try(:email)
    end

    def different?
      differences.any?
    end

    def identical?
      !different?
    end

    # field_name: [mailchimp_value, ffcrm_value]
    def differences
      diff = {}
      if contact.nil?
        diff = { base: ['Exists only in Mailchimp', ''] }
      elsif member.nil?
        diff = { base: ['', 'Exists only in FFCRM'] }
      else
        diff.merge! compare(:first_name)
        diff.merge! compare(:last_name)
        diff.merge! compare(:phone)
        diff.merge! compare_groups
        diff.merge! compare( config.consent_field_name )
        %w(street1 street2 city state zipcode country).each do |attr|
          diff.merge! compare_address( attr )
        end
      end
      diff
    end

    private

    # Useful for :first_name, :last_name, :phone
    # compare(:first_name)
    def compare(attribute)
      mc_val = member.send(attribute)
      ffcrm_val = contact.send(attribute)
      if mc_val != ffcrm_val
        { "#{attribute}".to_sym => [mc_val, ffcrm_val] }
      else
        {}
      end
    end

    def compare_groups
      if mailchimp_groups != contact_groups
        { groups: [mailchimp_groups.to_a.join(', '), contact_groups.to_a.join(', ')] }
      else
        {}
      end
    end

    def compare_address(attribute)
      mc_val = member.send(attribute)
      ffcrm_val = contact_address.try(:send, attribute)
      ffcrm_val = country_lookup(ffcrm_val) if attribute.to_s == 'country'
      if mc_val != ffcrm_val
        { "#{attribute}".to_sym => [mc_val, ffcrm_val] }
      else
        {}
      end
    end

    def mailchimp_groups
      Set.new( member.groups )
    end

    def contact_groups
      subscription = FfcrmMailchimp::ListSubscription.new( contact.send(cf_mailchimp_list_name) )
      Set.new( (subscription.groupings || []).map{|x| x['groups']}.flatten.compact )
    end

    def list_id
      member.list_id
    end

    #
    # Returns the column name of the custom field mailchimp list on Contacts table
    def cf_mailchimp_list_name
      @cf_mailchimp_list_name ||= begin
        config.mailchimp_list_fields.select{|f| f.list_id == list_id }.first.name
      end
    end

    def config
      FfcrmMailchimp.config
    end

    def contact_address
      address_type = FfcrmMailchimp.config.address_type
      contact.addresses.where(address_type: address_type).first
    end

    # AU => Australia
    def country_lookup(code)
      Hash[ActionView::Helpers::FormOptionsHelper::COUNTRIES].invert[code]
    end

  end

end
