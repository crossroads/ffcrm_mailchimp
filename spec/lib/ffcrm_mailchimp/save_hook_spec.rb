require 'spec_helper'

describe 'save_hook' do

  it "should hook into the update lifecycle of a contact" do
    contact = FactoryGirl.build(:contact)
    FfcrmMailchimp::OutboundSync.should_receive(:subscribe).with(contact)
    contact.email = "test-#{contact.email}"
    contact.save
  end

  it "should hook into the delete lifecycle of a contact" do
    contact = FactoryGirl.create(:contact)
    FfcrmMailchimp::OutboundSync.should_receive(:unsubscribe).with(contact)
    contact.destroy
  end

end
