Rails.application.routes.draw do

  get "/admin/ffcrm_mailchimp" => "admin/ffcrm_mailchimp#index",   format: 'html'
  put "/admin/ffcrm_mailchimp" => "admin/ffcrm_mailchimp#update",  format: 'html'
  put "/admin/ffcrm_mailchimp/reload_cache" => "admin/ffcrm_mailchimp#reload_cache", format: 'html'
  put "/admin/ffcrm_mailchimp/refresh_from_mailchimp" => "admin/ffcrm_mailchimp#refresh_from_mailchimp", format: 'html'
  put "/admin/ffcrm_mailchimp/destroy_custom_fields" => "admin/ffcrm_mailchimp#destroy_custom_fields", format: 'html'
  put "/admin/ffcrm_mailchimp/clear_crm_mailchimp_data" => "admin/ffcrm_mailchimp#clear_crm_mailchimp_data", format: 'html'
  get "/admin/ffcrm_mailchimp/compare" => "admin/ffcrm_mailchimp#compare", format: 'html'

end
