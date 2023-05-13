require 'ffcrm_mailchimp'

class Admin::FfcrmMailchimpController < Admin::ApplicationController

  before_filter :require_user
  before_filter "set_current_tab('admin/ffcrm_mailchimp')"

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

  def reload_cache
    FfcrmMailchimp.reload_cache
    flash[:info] = "List and group caches reloaded"
    redirect_to( action: 'index' )
  end

  def refresh_from_mailchimp
    FfcrmMailchimp.refresh_from_mailchimp!
    flash[:info] = "This job has been queued to run as a delayed job. Data will be reloaded from Mailchimp in the background."
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
