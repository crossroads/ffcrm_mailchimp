class Admin::FfcrmMailchimpController < Admin::ApplicationController

  before_filter :require_user
  before_filter "set_current_tab('admin/ffcrm_mailchimp')"

  # GET /admin/ffcrm_mailchimp
  #----------------------------------------------------------------------------
  def index
    @config = FfcrmMailchimp.config
  end

  def update
    FfcrmMailchimp.config.update!(params)
    flash[:info] = "Settings saved."
    redirect_to( action: 'index')
  end

  def reprime
    FfcrmMailchimp::CacheMonkey.prime
    flash[:info] = "List and group caches reloaded"
    redirect_to( action: 'index')
  end

end
