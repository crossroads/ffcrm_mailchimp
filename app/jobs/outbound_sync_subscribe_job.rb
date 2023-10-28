class OutboundSyncSubscribeJob < ApplicationJob
  queue_as :default

  # subscribed_email is the email address currently registered on the mailchimp list
  # Note: if contact is having it's email address updated, we must use the old email address to update the mailchimp lists
  def perform(record, subscribed_email)
    FfcrmMailchimp::OutboundSync.new(record, subscribed_email).subscribe
  end
end
