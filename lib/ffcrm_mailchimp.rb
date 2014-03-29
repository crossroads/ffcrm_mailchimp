require "ffcrm_mailchimp/config"
require "ffcrm_mailchimp/engine"
require "ffcrm_mailchimp/list"
require "ffcrm_mailchimp/refresh"
require "delayed_job_active_record"

module FfcrmMailchimp

  class << self

    # Access configuration specific to this engine
    def config
      FfcrmMailchimp::Config.new
    end

    def reload_cache
      FfcrmMailchimp::List.reload_cache
    end

    def refresh_from_mailchimp!
      FfcrmMailchimp::Refresh.delay.refresh_from_mailchimp!
    end

    def destroy_custom_fields!
      FfcrmMailchimp::Refresh.destroy_custom_fields!
    end

    def clear_crm_mailchimp_data!
      FfcrmMailchimp::Refresh.clear_crm_mailchimp_data!
    end

    def logger(message)
      if config.verbose
        Rails.logger.info("FfcrmMailchimp: #{message}")
      end
    end

  end

end
