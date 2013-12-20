require 'cgi'
require 'ffcrm_endpoint/endpoint'
require 'ffcrm_mailchimp/inbound_sync'

class FfcrmMailchimp::MailchimpEndpoint < FfcrmEndpoint::Endpoint

  # incoming requests are processed here in an action controller
  def process
    #~ FfcrmMailchimp::InboundSync.process(data)
    set_paper_trail_user
    webhook_response_type
  end

  # authenticate inbound webhooks from mailchimp must contain an api_key
  def authenticate
    api_key = FfcrmMailchimp.config.api_key
    api_key.present? && params[:api_key] == api_key
  end

  def subscribe
    cf_value = customfield_value
    contact = Contact.find_by_email(params[:data][:email])
    if contact.blank?
      record = Contact.create(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME],email: params[:data][:merges][:EMAIL])
      record.update_attributes(cf_value) unless cf_value.blank?
      record.save
    end
  end

  def profile_update
    cf_value = customfield_value
    contact = Contact.find_by_email(params[:data][:email])
    unless contact.blank?
      contact.update_attributes(first_name: params[:data][:merges][:FNAME],
        last_name: params[:data][:merges][:LNAME])
      contact.update_attributes(cf_value) unless cf_value.blank?
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
    cf_value = customfield_value
    contact = Contact.find_by_email(params[:data][:email])
    unless(contact.blank? || cf_value.blank?)
      cf_value[cf_value.map{|key,value| key}[0]] = []
      contact.update_attributes(cf_value)
      contact.save
    end
  end

  def customfield_value
    parameter = {}
    custom_field = Field.where("fields.as LIKE ? AND settings LIKE ?",
      "%mailchimp_list%", "%#{params[:data][:list_id]}%")
    unless custom_field.blank?
      cf_val =[]
      cf_val << "list_#{params[:data][:list_id]}"
      cf_val << "source_webhook"
      unless params[:data][:merges][:INTERESTS].blank?
        group_id = params[:data][:merges][:GROUPINGS]["0"][:id]
        groups = params[:data][:merges][:GROUPINGS]["0"]["groups"].split(",").collect(&:strip).map{|e| "#{group_id}_"+e}
        cf_val << groups
      end
      parameter = { custom_field.first.name => cf_val.flatten }
    end
    return parameter
  end

  private

  def data
    # parse an IronMQ request
    # CGI::parse(request.body.read)
    params
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

  # track changes against this user
  def set_paper_trail_user
    user_id = FfcrmMailchimp.config.user_id
    PaperTrail.whodunnit = user_id if defined?(PaperTrail) and user_id.present? and User.where(id: user_id).any?
  end

end
