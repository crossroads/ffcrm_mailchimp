require 'ffcrm_mailchimp/changes'
require 'ffcrm_mailchimp/outbound_sync'

module FfcrmMailchimp

  #
  # A proxy class to enable OutboundSync via delayed job.
  # We create a Changes class because ActiveRecord::Dirty is transient and probably won't survive a delayed_job queue
  class DelayedOutboundSync

    #
    # Look for changes and queue a subscription update if needed
    # Usage: FfcrmMailchimp::DelayedOutboundSync.subscribe(record)
    def self.subscribe(record)
      changes = FfcrmMailchimp::Changes.new(record)
      if changes.need_sychronization?
        if FfcrmMailchimp.config.sync_enabled?
          FfcrmMailchimp.logger.info("#{Time.now.to_s(:db)} FfcrmMailchimp::DelayedOutboundSync Queueing update to Mailchimp for #{record.class}##{record.id}")
          FfcrmMailchimp::OutboundSync.new(record, changes).delay.subscribe
        else
          FfcrmMailchimp.logger.info("#{Time.now.to_s(:db)} FfcrmMailchimp::DelayedOutboundSync Sync disabled and therefore not queueing update to Mailchimp for #{record.class}##{record.id}")
        end
      else
        FfcrmMailchimp.logger.info("#{Time.now.to_s(:db)} FfcrmMailchimp::DelayedOutboundSync No changes require update to Mailchimp for #{record.class}##{record.id}")
      end
    end

    #
    # Always need to sync if contact is deleted.
    def self.unsubscribe(record)
      if FfcrmMailchimp.config.sync_enabled?
        FfcrmMailchimp.logger.info("#{Time.now.to_s(:db)} FfcrmMailchimp::DelayedOutboundSync Scheduled Mailchimp list deletion for deleted contact #{record.class}##{record.id} - #{record.email}")
        FfcrmMailchimp::OutboundSync.delay.unsubscribe(record.email)
      else
        FfcrmMailchimp.logger.info("#{Time.now.to_s(:db)} FfcrmMailchimp::DelayedOutboundSync Sync disabled and therefore ignored list deletion for deleted contact #{record.class}##{record.id} - #{record.email}")
      end
    end

  end

end
