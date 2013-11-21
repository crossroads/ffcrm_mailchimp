require 'ffcrm_mailchimp'

module FfcrmMailchimp

  #
  # Receive incoming mailchimp webhooks and update FFCRM
  class InboundSync

    attr_accessor :params

    # call using FfcrmMailchimp::InboundSync.process(params)
    def self.process(params)
      new(params).process
    end

    def initialize(params)
      @params = params
    end

    private

    # Make any changes to CRM contacts.
    def process
      Rails.logger.info("FfcrmMailchimp::InboundSync received #{@params}")
    end

  end

end
