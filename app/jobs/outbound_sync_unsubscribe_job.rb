class OutboundSyncUnsubscribeJob < ApplicationJob
  queue_as :default

  def perform(email)
    FfcrmMailchimp::OutboundSync.unsubscribe(email)
  end
end
