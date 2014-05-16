require 'ffcrm_mailchimp/config'
require 'ffcrm_mailchimp/comparision'
require 'ffcrm_mailchimp/list_subscription'

module FfcrmMailchimp

  #
  # Compares mailchimp lists to FFCRM data and reveals the differences
  class Compare

    attr_accessor :list_id

    def initialize(list_id)
      @list_id = list_id
    end

    #
    # Return only different objects (i.e. remove all identical ones)
    def different
      compare.select(&:different?)
    end

    def count_members
      members.count
    end

    def count_contacts
      contacts.count
    end

    def list
      FfcrmMailchimp::List.find(@list_id)
    end

    private

    #
    # Return an array of comparision objects
    def compare
      @compare ||= (compare_mailchimp_to_ffcrm + compare_ffcrm_to_mailchimp)
    end

    #
    # Goes through a Mailchimp list and compares to FFCRM contacts
    # Returns a list of Comparision classes
    def compare_mailchimp_to_ffcrm
      members.collect do |member|
        contact = find_contact(member.email)
        FfcrmMailchimp::Comparision.new(member, contact, cf_mailchimp_list_name)
      end
    end

    #
    # Grab the list of contacts in CRM that have a list subscription for this list_id
    # but don't have an entry in mailchimp at all
    def compare_ffcrm_to_mailchimp
      contacts.select{ |contact| !members_by_email.keys.include?(contact.email) }.collect do |contact|
        FfcrmMailchimp::Comparision.new(nil, contact, cf_mailchimp_list_name)
      end
    end

    def members
      @members ||= FfcrmMailchimp::List.find(list_id).members
    end

    # hash { email => member } for fast lookup reference
    def members_by_email
      @members_by_email ||= members.inject({}){ |h,v| h[v.email] = v; h }
    end

    #
    # Find the contact in FFCRM
    def find_contact(email)
      #Contact.where(email: email).order(:id).first #.includes(:addresses)
      @member_contacts ||= preload_contacts_for_members
      @member_contacts[email]
    end

    #
    # Does a large query to get all contact records for the member email addresses
    # Speeds up the comparision
    def preload_contacts_for_members
      member_contacts = {}
      emails = members.map{|m| m.email }
      Contact.where(email: emails).order(:id).each do |c| #.includes(:addresses)
        member_contacts.merge!( "#{c.email}" => c ) unless member_contacts.has_key?(c.email) # only take the first one
      end
      member_contacts
    end

    #
    # Find all the FFCRM contacts that think they have a mailchimp subscription
    # Candidates include those with mailchimp field != {} and not {:source => "ffcrm"} (i.e. a hash with no list_id)
    def contacts
      @contacts ||= begin
        potentials = Contact.where( Contact.arel_table[cf_mailchimp_list_name].not_eq(nil) )#.includes(:addresses)
        potentials.select do |p|
          val = p.send(cf_mailchimp_list_name)
          FfcrmMailchimp::ListSubscription.new(val).has_list?
        end
      end
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
