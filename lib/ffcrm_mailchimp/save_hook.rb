# When a contact is saved, ensure the mailchimp process hook is fired.
ActiveSupport.on_load(:fat_free_crm_contact) do

  require 'ffcrm_mailchimp/delayed_outbound_sync'

  after_save { |record| FfcrmMailchimp::DelayedOutboundSync.subscribe(record) }
  after_destroy { |record| FfcrmMailchimp::DelayedOutboundSync.unsubscribe(record) }

end
