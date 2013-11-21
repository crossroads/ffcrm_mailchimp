module FfcrmMailchimp
  class Engine < ::Rails::Engine

    config.to_prepare do

      # Add admin/ffcrm_mailchimp tab
      tab_urls = FatFreeCRM::Tabs.admin.map{|tab| tab[:url]}.map{|url| url[:controller]}
      unless tab_urls.include? 'admin/ffcrm_mailchimp'
        FatFreeCRM::Tabs.admin << {:url => { :controller => "admin/ffcrm_mailchimp" }, :text => "Mailchimp"}
      end

      # When a contact is saved, ensure the mailchimp process hook is fired.
      require 'ffcrm_mailchimp/save_hook'

      # Setup a webhook endpoint to receive incoming mailchimp updates
      require 'ffcrm_mailchimp/mailchimp_endpoint'

    end

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end

  end
end
