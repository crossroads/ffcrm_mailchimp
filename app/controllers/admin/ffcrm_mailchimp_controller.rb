class Admin::FfcrmMailchimpController < Admin::ApplicationController

  before_filter :require_user
  before_filter "set_current_tab('admin/ffcrm_mailchimp')", :only => [ :index, :update ]

  # GET /admin/ffcrm_mailchimp
  #----------------------------------------------------------------------------
  def index
    @config = FfcrmMailchimp.config
  end

  def update
    FfcrmMailchimp.config.update!(params)
    flash[:info] = "Api key saved."
    redirect_to( action: 'index')
  end

end
