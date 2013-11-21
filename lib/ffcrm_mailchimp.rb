require "ffcrm_mailchimp/config"
require "ffcrm_mailchimp/engine"

module FfcrmMailchimp

  class << self

    # Access configuration specifc to this engine
    def config
      FfcrmMailchimp::Config.new
    end

  end

end
