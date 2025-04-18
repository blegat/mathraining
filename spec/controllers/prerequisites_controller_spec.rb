# -*- coding: utf-8 -*-
require "spec_helper"

describe PrerequisitesController, type: :controller, prerequisite: true do

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:prerequisite) { FactoryBot.create(:prerequisite) }
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('prerequisite', :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(prerequisite, :access_refused) }
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(user) }
    
    context "but the chapter is online" do
      before { prerequisite.chapter.update_attribute(:online, true) }
      
      it { expect(response).to have_controller_destroy_behavior(prerequisite, :access_refused) }
    end
  end
end
