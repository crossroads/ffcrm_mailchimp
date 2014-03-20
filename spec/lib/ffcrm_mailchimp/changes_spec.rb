require 'spec_helper'

describe FfcrmMailchimp::Changes do

  let(:contact) { FactoryGirl.build(:contact) }
  let(:changes) { FfcrmMailchimp::Changes.new(contact) }

  context "email changed" do

    let(:old_email) { contact.email }
    let(:new_email) { "new-#{old_email}" }

    before { contact.stub(:email_change) { [old_email, new_email] } }

    it { expect( changes.email_changed? ).to be_true }
    it { expect( changes.old_email ).to eql( old_email ) }
    it { expect( changes.new_email ).to eql( new_email ) }

  end

end
