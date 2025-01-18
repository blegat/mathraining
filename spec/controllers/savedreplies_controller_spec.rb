# -*- coding: utf-8 -*-
require "spec_helper"

describe SavedrepliesController, type: :controller, savedreply: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:savedreply) { FactoryGirl.create(:savedreply) }
  
  context "if the user is not an root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('savedreply', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(savedreply, :access_refused) }
    it { expect(response).to have_controller_update_behavior(savedreply, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(savedreply, :access_refused) }
  end
end
