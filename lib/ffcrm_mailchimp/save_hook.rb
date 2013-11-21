# When a contact is saved, ensure the mailchimp process hook is fired.
ActiveSupport.on_load(:fat_free_crm_contact) do

  require 'ffcrm_mailchimp/sync'

  after_save do |record|
    FfcrmMailchimp::Sync.process(record)
  end

end
