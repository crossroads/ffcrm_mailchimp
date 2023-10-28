module FfcrmMailchimp
  class Engine < ::Rails::Engine

    paths["app/models"] << "app/models/fields/"

    config.to_prepare do

      # Register the mailchimp lists custom field
      Field.register( as: 'mailchimp_list', klass: 'CustomFieldMailchimpList', type: 'text')

      # Add admin/ffcrm_mailchimp tab
      ActiveSupport.on_load(:fat_free_crm_view_factory) do
        tab_urls = FatFreeCRM::Tabs.admin.map{|tab| tab[:url]}.map{|url| url[:controller]}
        unless tab_urls.include? 'admin/ffcrm_mailchimp'
          FatFreeCRM::Tabs.admin << {url: { controller: "admin/ffcrm_mailchimp" }, text: "Mailchimp", icon: 'fa-envelope'}
        end
      end

      # When a contact is saved, ensure the mailchimp process hook is fired.
      require 'ffcrm_mailchimp/save_hook'

      # If subgroup_only is checked, validate to ensure at least one subgroup has been checked.
      require 'ffcrm_mailchimp/subgroup_validation'

      # Setup a webhook endpoint to receive incoming mailchimp updates
      require 'ffcrm_mailchimp/mailchimp_endpoint'

      # Turn on serialization for any mailchimp fields at exist at bootup
      ActiveSupport.on_load(:active_record) do
        FfcrmMailchimp.config.mailchimp_list_fields.map(&:apply_serialization)
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      end

    end

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end

  end
end
