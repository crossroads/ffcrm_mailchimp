require 'cgi'
require 'ffcrm_endpoint'
require 'ffcrm_mailchimp/inbound_sync'

class FfcrmMailchimp::MailchimpEndpoint < FfcrmEndpoint::Endpoint

  # incoming requests are processed here in an action controller
  def process
    FfcrmMailchimp::InboundSync.process(data)
  end

  # authenticate inbound webhooks from mailchimp must contain an api_key
  def authenticate
    #~ api_key = FfcrmMailchimp.config.api_key
    #~ api_key.present? && params[:api_key] == api_key
    debugger
    true
  end

  private

  def data
    # parse an IronMQ request
    # CGI::parse(request.body.read)
    params
  end

end
