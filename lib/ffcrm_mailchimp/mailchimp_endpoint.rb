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
    response_type
    api_key.present? && params[:api_key] == api_key
  end

  def subscribe
    contact = Contact.find_by_email(params[:data][:email])
    if contact.blank?
      record = Contact.create(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME],email: params[:data][:merges][:EMAIL])
      record.save
    end
  end

  def profile_update
    contact = Contact.find_by_email(params[:data][:email])
    unless contact.blank?
      contact.update_attributes(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME])
      contact.save
    end
  end

  def email_changed
    old_contact = Contact.find_by_email(params[:data][:old_email])
    new_contact = Contact.find_by_email(params[:data][:new_email])
    if(old_contact.present? && new_contact.blank? && params[:data][:new_email].present?)
      old_contact.update_attributes(email: params[:data][:new_email])
      old_contact.save
    end
  end

  def unsubscribe

  end

  def response_type
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
  end

  private

  def data
    # parse an IronMQ request
    # CGI::parse(request.body.read)
    params
  end

end
