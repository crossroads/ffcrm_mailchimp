# When a contact is saved, ensure the mailchimp process hook is fired.
ActiveSupport.on_load(:fat_free_crm_contact) do

  require 'ffcrm_mailchimp/outbound_sync'

  after_save    { |record| FfcrmMailchimp::OutboundSync.subscribe(record) }
  after_destroy { |record| FfcrmMailchimp::OutboundSync.unsubscribe(record) }

end
