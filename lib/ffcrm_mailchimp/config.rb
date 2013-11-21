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

  end

end
