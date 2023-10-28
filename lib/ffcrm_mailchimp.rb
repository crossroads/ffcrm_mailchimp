require "ffcrm_mailchimp/config"
require "ffcrm_mailchimp/engine"
require "ffcrm_mailchimp/list"
require "ffcrm_mailchimp/refresh"

module FfcrmMailchimp

  class << self

    # Access configuration specific to this engine
    def config
      FfcrmMailchimp::Config.new
    end

    def clear_cache
      FfcrmMailchimp::Api.clear_cache
    end

    def destroy_custom_fields!
      FfcrmMailchimp::Refresh.destroy_custom_fields!
    end

    def clear_crm_mailchimp_data!
      FfcrmMailchimp::Refresh.clear_crm_mailchimp_data!
    end

    def logger
      @@logger ||= begin
        level = config.verbose ? Logger::INFO : Logger::ERROR
        Logger.new(File.join(Rails.root, 'log', 'ffcrm_mailchimp.log'))
      end
    end

    def lists
      FfcrmMailchimp::List.lists
    end

  end

end
