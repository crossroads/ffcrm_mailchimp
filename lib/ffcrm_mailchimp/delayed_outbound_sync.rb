require 'ffcrm_mailchimp/changes'
require 'ffcrm_mailchimp/outbound_sync'

module FfcrmMailchimp

  #
  # A proxy class to enable OutboundSync via ActiveJob.
  # We create a Changes class because ActiveRecord::Dirty is transient and probably won't survive an ActiveJob queue
  class DelayedOutboundSync

    #
    # Look for changes and queue a subscription update if needed
    # Usage: FfcrmMailchimp::DelayedOutboundSync.subscribe(record)
    def self.subscribe(record)
      changes = FfcrmMailchimp::Changes.new(record)
      if changes.need_sychronization?
        if FfcrmMailchimp.config.sync_enabled?
          FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::DelayedOutboundSync Queueing update to Mailchimp for #{record.class}##{record.id}")
          subscribed_email = changes.old_email || record.email # important to match correct record if email is being changed.
          OutboundSyncSubscribeJob.perform_later(record, subscribed_email)
        else
          FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::DelayedOutboundSync Sync disabled and therefore not queueing update to Mailchimp for #{record.class}##{record.id}")
        end
      else
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::DelayedOutboundSync No changes require update to Mailchimp for #{record.class}##{record.id}")
      end
    end

    #
    # Always need to sync if contact is deleted.
    def self.unsubscribe(record)
      if FfcrmMailchimp.config.sync_enabled?
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::DelayedOutboundSync Scheduled Mailchimp list deletion for deleted contact #{record.class}##{record.id} - #{record.email}")
        OutboundSyncUnsubscribeJob.perform_later(record.email)
      else
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::DelayedOutboundSync Sync disabled and therefore ignored list deletion for deleted contact #{record.class}##{record.id} - #{record.email}")
      end
    end

  end

end
