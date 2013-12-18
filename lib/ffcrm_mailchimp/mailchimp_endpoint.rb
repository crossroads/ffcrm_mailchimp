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
    webhook_response_type
    api_key.present? && params[:api_key] == api_key
  end

  def subscribe
    value = customfield_value
    contact = Contact.find_by_email(params[:data][:email])
    if contact.blank?
      record = Contact.create(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME],email: params[:data][:merges][:EMAIL])
      record.update_attributes(value) unless value.blank?
      record.save
    end
  end

  def profile_update
    value = customfield_value
    contact = Contact.find_by_email(params[:data][:email])
    unless contact.blank?
      contact.update_attributes(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME])
      contact.update_attributes(value) unless value.blank?
      contact.save
    end
  end

  def email_changed
    old_email = Contact.find_by_email(params[:data][:old_email])
    new_email = Contact.find_by_email(params[:data][:new_email])
    if(old_email.present? && new_email.blank? && params[:data][:new_email].present?)
      old_email.update_attributes(email: params[:data][:new_email])
      old_email.save
    end
  end

  def unsubscribe
    value = customfield_value
    contact = Contact.find_by_email(params[:data][:email])
    unless(contact.blank? && value.blank?)
      value[value.map{|key,value| key}[0]] = []
      contact.update_attributes(value)
      contact.save
    end
  end

  def customfield_value
    list_id_present = Field.select("settings").where(as: 'mailchimp_list').map{|list| list.settings[:list_id]}.
      include? params[:data][:list_id]
    list_name = FfcrmMailchimp::List.get(params[:data][:list_id]).name unless list_id_present.blank?
    if list_name
      column_name = 'cf_' + list_name.downcase.gsub(/[^a-z0-9]+/, '_')
      column = Contact.column_names.include? column_name if list_name
    end
    parameter = { "#{column_name}" => [params[:data][:merges][:INTERESTS]] } if(column.present? && params[:data][:merges][:INTERESTS].present?)
    return parameter
  end

  def webhook_response_type
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
