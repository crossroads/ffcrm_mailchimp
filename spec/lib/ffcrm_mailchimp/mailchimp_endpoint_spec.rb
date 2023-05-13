require 'spec_helper'
describe FfcrmMailchimp::MailchimpEndpoint do

  let(:api_key)     { "1f443fda6e6fab633b8509asdsdhga34234-us3" }
  let(:params)      { FactoryGirl.build(:mc_webhook, api_key: api_key) }
  let(:request)     { double(params: params) }
  let(:mc_endpoint) { FfcrmMailchimp::MailchimpEndpoint.new(request) }

  describe "authenticate" do

    context "with correct api_key" do
      before { FfcrmMailchimp.stub(:config).and_return( double(api_key: api_key) ) }
      it { expect( mc_endpoint.authenticate ).to eql(true) }
    end

    context "with invalid api_key" do
      before { FfcrmMailchimp.stub(:config).and_return( double(api_key: "qwerty") ) }
      it { expect( mc_endpoint.authenticate ).to eql(false) }
    end

    context "with blank api_key" do
      before { FfcrmMailchimp.stub(:config).and_return( double(api_key: "") ) }
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
