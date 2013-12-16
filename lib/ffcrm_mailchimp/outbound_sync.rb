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
      list_subscriptions_changes.each do |column|
        custom_field_value = @record.send column
        if custom_field_value.present?
          list_id = Field.where("name = ?", column).first.settings[:list_id]
          unless custom_field_value.first["groupings"].blank?
            group_id = custom_field_value.first["groupings"].first["group_id"]
            groups = custom_field_value.first["groupings"].first["groups"]
          end

          if !is_subscribed_mailchimp_user(list_id, @record.email)
            subscribe_to_mailchimp_group(list_id, @record.email, group_id, groups) #new contact
          elsif @record.send "#{column}_changed?"
            update_subscription_to_mailchimp(list_id, @record.email, group_id, groups)
          end
        else
          list_id = @record.send(column+"_was").first["list_id"]
          unsubscribe_from_mailchimp_group(list_id, @record.email)
        end
      end

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

    def subscribe_to_mailchimp_group(list_id, email, group_id, groups)
      (Config.new.mailchimp_api).lists.subscribe({:id => list_id, :email => {:email => email},
        :merge_vars => {:FNAME => @record.first_name, :LNAME => @record.last_name,
          groupings: [{id: group_id, groups: groups }]}, :double_optin => false})
    end

    def unsubscribe_from_mailchimp_group(list_id, email)
      (Config.new.mailchimp_api).lists.unsubscribe(id: list_id,
        email: {email: email})
    end

    def update_subscription_to_mailchimp(list_id, email, group_id, groups)
      (Config.new.mailchimp_api).lists.subscribe({:id => list_id, :email => {:email => email},
        :merge_vars => {:FNAME => @record.first_name, :LNAME => @record.last_name,
          groupings: [{id: group_id, groups: groups }]}, :update_existing => "true", :double_optin => false})
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
