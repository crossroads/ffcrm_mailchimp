Rails.application.routes.draw do

  get "/admin/ffcrm_mailchimp" => "admin/ffcrm_mailchimp#index",  format: 'html'
  put "/admin/ffcrm_mailchimp" => "admin/ffcrm_mailchimp#update", format: 'html'

end
