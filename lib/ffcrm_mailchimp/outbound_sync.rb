module FfcrmMailchimp

  #
  # Process contact updates from FFCRM to Mailchimp
  class OutboundSync

    attr_accessor :record

    # call using FfcrmMailchimp::OutboundSync.process(record)
    def self.process(record)
      new(record).process
    end

    def initialize(record)
      @record = record
    end

    # Determine if we need to send changes to Mailchimp.
    def process
      # list_subscriptions_changes.each do |column|
      #   custom_field_value = @record.send column
      #   list_id, groups = [], []
      #   custom_field_value.map{|val|
      #     val.starts_with?('list_') ? list_id = val.split('_')[1] :
      #     groups << val
      #   }
      #   if custom_field_value.present?
      #     if !is_subscribed_mailchimp_user(list_id, @record.email)
      #       subscribe_to_mailchimp_group(list_id, @record.email, groups) #new contact
      #     elsif @record.cf_test_changed?
      #       update_subscription_to_mailchimp
      #     end
      #   else
      #     unsubscribe_from_mailchimp_group
      #   end
      # end

      if email_changes.present? or list_subscriptions_changes.present?
        synchronise!
        #~ TODO
        #~ if defined?(delay)
          #~ delay.synchronise! # add as a delayed_job
        #~ else
          #~ synchronise!
        #~ end
      end
    end
    #Check whether this email exists or  not?
    def is_subscribed_mailchimp_user(list_id, email)
      (Config.new.mailchimp_api).lists.member_info({id: list_id,
        emails: [{email:email}]})["error_count"].zero?
      #If exists then check which all groups are active if selected it not available then update the contact
    end

    def subscribe_to_mailchimp_group(list_id, email, groups)
      # (Config.new.mailchimp_api).lists.subscribe(id: list_id,
      #   email: {email: email}, merge_vars: {groupings: [{name: "Groups", groups: ["group2"] }]})
      debugger
      (Config.new.mailchimp_api).lists.subscribe({id: list_id, email: {email: email},
        merge_vars: {FNAME: @record.first_name, LNAME: @record.last_name, INTERESTS: groups}})
    end

    def unsubscribe_from_mailchimp_group
      (Config.new.mailchimp_api).lists.unsubscribe(id: "1f1b028b64",
        email: {email: "sunil.sharma@kiprosh.com"}, merge_vars: {groupings: [{name: "Test Group", groups: ["group 3"] }]})
    end

    def update_subscription_to_mailchimp
      (Config.new.mailchimp_api).lists.update_member(id: "1f1b028b64",
        email: {email: "sunil.sharma@kiprosh.com"}, merge_vars: {groupings: [{name: "Test Group", groups: ["group 3"] }]})
    end

    private

    # Changes to the email address on the record
    # Either nil or an array ['test@example.com', 'testing@example.com']
    # Depends on ActiveRecord::Dirty
    def email_changes
      @record.email_change
    end

    # Changes to the list subscriptions on the record
    # Either nil or an array ['listA', 'listB']
    def list_subscriptions_changes
      # fields is the list of mailchimp list fields that we're interested in checking for changes.
      fields = []
      changes = Field.where(as: 'mailchimp_list').collect do |field|
        fields << field.name if @record.send("#{field.name}_changed?")
      end
      return fields
    end

    # send updates to mailchimp
    def synchronise!
      Rails.logger.info("FfcrmMailchimp: Contact #{@record.id} was updated")
    end
  end

end
