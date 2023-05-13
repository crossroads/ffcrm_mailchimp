require 'cgi'
require 'ffcrm_endpoint/endpoint'
require 'ffcrm_mailchimp/inbound_sync'

class FfcrmMailchimp::MailchimpEndpoint < FfcrmEndpoint::Endpoint

  #
  # Incoming requests are processed here inside an action controller
  def process
    set_paper_trail_user
    FfcrmMailchimp::InboundSync.process(data)
  end

  #
  # Authenticate inbound webhooks from mailchimp. Must contain a valid api_key
  def authenticate
    api_key = FfcrmMailchimp.config.api_key
    api_key.present? && params[:api_key] == api_key
  end

  private

  #
  # Attribute updates in FFCRM to a particular user
  def set_paper_trail_user
    user_id = FfcrmMailchimp.config.user_id
    PaperTrail.whodunnit = user_id if defined?(PaperTrail) and user_id.present? and User.where(id: user_id).any?
  end

  def data
    params
  end

end
