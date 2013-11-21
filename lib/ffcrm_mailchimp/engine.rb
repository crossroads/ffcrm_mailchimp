module FfcrmMailchimp
  class Engine < ::Rails::Engine

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    config.to_prepare do
      tab_urls = FatFreeCRM::Tabs.admin.map{|tab| tab[:url]}.map{|url| url[:controller]}
      unless tab_urls.include? 'admin/ffcrm_mailchimp'
        FatFreeCRM::Tabs.admin << {:url => { :controller => "admin/ffcrm_mailchimp" }, :text => "Mailchimp"}
      end
    end

  end
end
