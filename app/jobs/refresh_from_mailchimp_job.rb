class RefreshFromMailchimpJob < ApplicationJob
  queue_as :default

  def perform(email_addresses)
    FfcrmMailchimp::Refresh.refresh_from_mailchimp(email_addresses)
  end
end
