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
        [:compare_first_name, :compare_last_name, :compare_groups].each do |meth|
          diff.merge!( send(meth) )
        end
      end
      diff
    end

    private

    def compare_first_name
      if member.first_name != contact.first_name
        { first_name: [member.first_name, contact.first_name] }
      else
        {}
      end
    end

    def compare_last_name
      if member.last_name != contact.last_name
        { last_name: [member.last_name, contact.last_name] }
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

    def mailchimp_groups
      Set.new( member.groupings.map{ |key, value| value['groups'] }.flatten.compact )
    end

    def contact_groups
      subscription = FfcrmMailchimp::ListSubscription.new( contact.send(cf_mailchimp_list_name) )
      Set.new( subscription.groupings.map{|x| x['groups']}.flatten.compact )
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

  end

end
