# -*- coding: utf-8 -*-
require "spec_helper"

describe ExtractsController, type: :controller, extract: true do

  let(:user) { FactoryBot.create(:user) }
  let(:externalsolution) { FactoryBot.create(:externalsolution) }
  let(:extract) { FactoryBot.create(:extract) }
  
  context "if the user is not an signed in" do 
    it { expect(response).to have_controller_create_behavior('extract', :access_refused, {:externalsolution_id => externalsolution.id}) }
    it { expect(response).to have_controller_update_behavior(extract, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(extract, :access_refused) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_create_behavior('extract', :access_refused, {:externalsolution_id => externalsolution.id}) }
    it { expect(response).to have_controller_update_behavior(extract, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(extract, :access_refused) }
  end
end
