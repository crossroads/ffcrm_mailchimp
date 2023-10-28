require 'ffcrm_mailchimp'

class Admin::FfcrmMailchimpController < Admin::ApplicationController

  before_action -> { set_current_tab('admin/ffcrm_mailchimp') }

  # GET /admin/ffcrm_mailchimp
  #----------------------------------------------------------------------------
  def index
    @config = FfcrmMailchimp.config
    @lists = active_lists
  end

  def update
    FfcrmMailchimp.config.update!(params)
    flash[:info] = "Settings saved."
    redirect_to( action: 'index' )
  end

  def clear_cache
    FfcrmMailchimp.clear_cache
    flash[:info] = "Mailchimp list and group caches cleared."
    redirect_to( action: 'index' )
  end

  def refresh_from_mailchimp
    email_addresses = (params['email_addresses'] || "").split(",").map(&:strip).uniq
    if email_addresses.blank?
      flash[:info] = "Please provide at least one email address to reload from Mailchimp"
    else
      RefreshFromMailchimpJob.perform_later(email_addresses)
      flash[:info] = "This job has been queued to run as a backgruond job. Data for matching email addresses will be reloaded from Mailchimp in the background."
    end
    redirect_to( action: 'index' )
  end

  def destroy_custom_fields
    FfcrmMailchimp.destroy_custom_fields!
    flash[:info] = "All CRM Mailchimp List custom fields and associated data have been removed."
    redirect_to( action: 'index' )
  end

  def clear_crm_mailchimp_data
    FfcrmMailchimp.clear_crm_mailchimp_data!
    flash[:info] = "All Mailchimp data in CRM has been cleared."
    redirect_to( action: 'index' )
  end

  private

  #
  # Returns only mailchimp lists that are used in custom fields
  def active_lists
    lists = []
    FfcrmMailchimp.config.mailchimp_list_fields.each do |field|
      lists << FfcrmMailchimp::List.find( field.list_id )
    end
    lists
  end

end
