# -*- coding: utf-8 -*-
require "spec_helper"

describe SectionsController, type: :controller, section: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  
  context "if the user is not connected" do    
    it { expect(response).to have_controller_show_behavior(section, :ok) }
    it { expect(response).to have_controller_edit_behavior(section, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(section, :access_refused) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_show_behavior(section, :ok) }
    it { expect(response).to have_controller_edit_behavior(section, :access_refused) }
    it { expect(response).to have_controller_update_behavior(section, :access_refused) }
  end
end
