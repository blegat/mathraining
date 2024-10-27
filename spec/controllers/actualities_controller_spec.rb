# -*- coding: utf-8 -*-
require "spec_helper"

describe ActualitiesController, type: :controller, actuality: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:actuality) { FactoryGirl.create(:actuality) }
  
  context "if the user is not signed in" do    
    it { expect(response).to have_controller_new_behavior(:must_be_connected) }
    it { expect(response).to have_controller_create_behavior('actuality', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(actuality, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(actuality, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(actuality, :access_refused) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('actuality', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(actuality, :access_refused) }
    it { expect(response).to have_controller_update_behavior(actuality, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(actuality, :access_refused) }
  end
end
