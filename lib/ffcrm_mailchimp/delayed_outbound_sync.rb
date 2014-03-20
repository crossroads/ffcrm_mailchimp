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
        FfcrmMailchimp::OutboundSync.new(record, changes).delay.subscribe
      end
    end

    #
    # Always need to sync if contact is deleted.
    def self.unsubscribe(record)
      changes = FfcrmMailchimp::Changes.new(record)
      FfcrmMailchimp::OutboundSync.new(record, changes).delay.unsubscribe
    end

  end

end
