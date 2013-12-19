require 'gibbon'

module FfcrmMailchimp

  class Config

    attr_accessor :config

    def initialize
      @config = Setting.ffcrm_mailchimp
    end

    #
    # Used in the admin section to apply settings
    def update!(options)
      @config = Setting.ffcrm_mailchimp = { api_key: options[:api_key] }
    end

    #
    # The api key is used to connect to Mailchimp accounts.
    def api_key
      config.present? ? config[:api_key] : nil
    end

    def mailchimp_api
      Gibbon::API.new(api_key)
    end

    # the id of a CRM user that will be the 'mailchimp' user in Papertrail
    def user_id
      config.present? ? config[:user_id] : nil
    end

  end

end
