require 'ffcrm_mailchimp'

module FfcrmMailchimp

  class Sync

    attr_accessor :record

    # call using FfcrmMailchimp::Sync.process(record)
    def self.process(record)
      new(record).process
    end

    def initialize(record)
      @record = record
    end

    private

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

    # Changes to the email address on the record
    # Either nil or an array ['test@example.com', 'testing@example.com']
    def email_changes
      @record.email_change
    end

    # Changes to the list subscriptions on the record
    # Either nil or an array ['listA', 'listB']
    def list_subscriptions_changes
      nil # TODO
    end

    # send updates to mailchimp
    def synchronise!
      Rails.logger.info("FfcrmMailchimp: Contact #{@record.id} was updated")
    end

  end

end
