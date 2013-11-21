require 'spec_helper'

describe 'save_hook' do

  let(:contact) { FactoryGirl.build(:contact) }

  it "should hook into the lifecycle of a contact" do
    FfcrmMailchimp::Sync.should_receive(:process).with(contact)
    contact.email = "test-#{contact.email}"
    contact.save
  end

end
