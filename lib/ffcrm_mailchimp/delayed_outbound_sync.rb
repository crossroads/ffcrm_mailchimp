require 'ffcrm_mailchimp/changes'
require 'ffcrm_mailchimp/outbound_sync'

module FfcrmMailchimp

  #
  # A proxy class to enable OutboundSync via delayed job.
  # We create a Changes class as ActiveRecord::Dirty probably won't survive a delayed_job queue
  class DelayedOutboundSync

    #
    # Look for changes and queue a subscription update if needed
    # Usage: FfcrmMailchimp::DelayedOutboundSync.subscribe(record)
    def self.subscribe(record)
      changes = FfcrmMailchimp::Changes.new(record)
      if changes.need_sychronization?
        FfcrmMailchimp.logger("Queueing update to mailchimp for #{record.class}##{record.id}")
        FfcrmMailchimp::OutboundSync.new(record, changes).delay.subscribe
      else
        FfcrmMailchimp.logger("No changes require update to mailchimp for #{record.class}##{record.id}")
      end
    end

    #
    # Always need to sync if contact is deleted.
    def self.unsubscribe(record)
      FfcrmMailchimp.logger("Scheduled mailchimp list deletion for deleted contact #{record.class}##{record.id} - #{record.email}")
      FfcrmMailchimp::OutboundSync.delay.unsubscribe(record.email)
    end

  end

end
