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
    def is_subscribed_mailchimp_user
      # (Config.new.mailchimp_api).lists.member_info({id: "80d6029b98",emails: [{email:"shefaly16@gmail.com"}]})
      #If exists then check which all groups are active if selected it not available then update the contact
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
      changes = Field.where(as: 'mailchimp_list').collect do |field|
        @record.send("#{field.name}_change")
      end.compact
    end

    # send updates to mailchimp
    def synchronise!
      Rails.logger.info("FfcrmMailchimp: Contact #{@record.id} was updated")
    end
  end

end
