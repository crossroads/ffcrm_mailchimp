Rails.application.routes.draw do

  get "/admin/ffcrm_mailchimp" => "admin/ffcrm_mailchimp#index",   format: 'html'
  put "/admin/ffcrm_mailchimp" => "admin/ffcrm_mailchimp#update",  format: 'html'
  put "/admin/ffcrm_mailchimp/clear_cache" => "admin/ffcrm_mailchimp#clear_cache", format: 'html'
  post "/admin/ffcrm_mailchimp/refresh_from_mailchimp" => "admin/ffcrm_mailchimp#refresh_from_mailchimp", format: 'html'
  put "/admin/ffcrm_mailchimp/destroy_custom_fields" => "admin/ffcrm_mailchimp#destroy_custom_fields", format: 'html'
  put "/admin/ffcrm_mailchimp/clear_crm_mailchimp_data" => "admin/ffcrm_mailchimp#clear_crm_mailchimp_data", format: 'html'

end
