require 'cgi'
require 'ffcrm_endpoint/endpoint'
require 'ffcrm_mailchimp/inbound_sync'

class FfcrmMailchimp::MailchimpEndpoint < FfcrmEndpoint::Endpoint

  # incoming requests are processed here in an action controller
  def process
    FfcrmMailchimp::InboundSync.process(data)
  end

  # authenticate inbound webhooks from mailchimp must contain an api_key
  def authenticate
    api_key = FfcrmMailchimp.config.api_key
    case params[:type]
    when "subscribe"
      subscribe
    when "profile"
      profile_update
    when "upemail"
      email_changed
    when "unsubscribe"
      unsubscribe
    else
    end
    api_key.present? && params[:api_key] == api_key
  end

  def subscribe
    user = User.find_by_email(params[:data][:email])
    if user.blank?
      record = User.create(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME],email: params[:data][:merges][:EMAIL])
      record.save
    end
  end

  def profile_update
    user = User.find_by_email(params[:data][:email])
    unless user.blank?
      user.update_attributes(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME])
      user.save
    end
  end

  def email_changed
    user = User.find_by_email(params[:data][:old_email])
    if(user.present? && params[:data][:new_email].present?)
      user.update_attributes(email: params[:data][:new_email])
      user.save
    end
  end

  def unsubscribe

  end

  private

  def data
    # parse an IronMQ request
    # CGI::parse(request.body.read)
    params
  end

end
