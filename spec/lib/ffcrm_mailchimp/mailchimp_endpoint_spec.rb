require 'spec_helper'
describe FfcrmMailchimp::MailchimpEndpoint do

  let(:webhook_key) { "akwdjffdke" }
  let(:params)      { FactoryGirl.build(:mc_webhook, webhook_key: webhook_key).with_indifferent_access }
  let(:request)     { double(params: params) }
  let(:mc_endpoint) { FfcrmMailchimp::MailchimpEndpoint.new(request) }

  describe "authenticate" do

    context "with correct webhook_key" do
      before { allow_any_instance_of(FfcrmMailchimp::Config).to receive(:webhook_key).and_return(webhook_key) }
      it { expect( mc_endpoint.authenticate ).to eql(true) }
    end

    context "with invalid webhook_key" do
      before { allow_any_instance_of(FfcrmMailchimp::Config).to receive(:webhook_key).and_return('qwerty') }
      it { expect( mc_endpoint.authenticate ).to eql(false) }
    end

    context "with blank webhook_key" do
      before { allow_any_instance_of(FfcrmMailchimp::Config).to receive(:webhook_key).and_return('') }
      it { expect( mc_endpoint.authenticate ).to eql(false) }
    end

  end

  describe "set_paper_trail_user" do

    let(:user) { FactoryGirl.create(:user) }

    before { PaperTrail.whodunnit = nil } # class variable needs resetting on each test run

    context "with valid user" do
      before {
        FfcrmMailchimp.stub(:config).and_return( double(user_id: user.id) )
        mc_endpoint.send(:set_paper_trail_user)
      }
      it { expect( PaperTrail.whodunnit ).to eql( user.id ) }
    end

    context "when user not found" do
      before {
        FfcrmMailchimp.stub(:config).and_return( double(user_id: user.id + 1) )
        mc_endpoint.send(:set_paper_trail_user)
       }
      it { expect( PaperTrail.whodunnit ).to eql( nil ) }
    end

    context "when user_id not set" do
      before {
        FfcrmMailchimp.stub(:config).and_return( double(user_id: nil) )
        mc_endpoint.send(:set_paper_trail_user)
       }
      it { expect( PaperTrail.whodunnit ).to eql( nil ) }
    end

  end

  describe "data" do

    context "with request" do
      it { expect( mc_endpoint.send(:data) ).to eql( params ) }
    end

  end

end
