require 'rails_helper'

describe 'save_hook' do

  describe "should hook into the update lifecycle of a contact" do
    let(:contact) { FactoryBot.build(:contact) }
    it do
      expect(FfcrmMailchimp::DelayedOutboundSync).to receive(:subscribe).with(contact).at_least(1).times
      contact.email = "test-#{contact.email}"
      contact.save
    end
  end

  describe "should hook into the delete lifecycle of a contact" do
    let(:contact) { FactoryBot.create(:contact) }
    it do
      expect(FfcrmMailchimp::DelayedOutboundSync).to receive(:unsubscribe).with(contact)
      contact.destroy
    end
  end

end
