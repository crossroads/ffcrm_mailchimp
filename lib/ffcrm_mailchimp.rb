require "ffcrm_mailchimp/config"
require "ffcrm_mailchimp/engine"

module FfcrmMailchimp

  class << self

    def config
      FfcrmMailchimp::Config.new
    end

  end

end
