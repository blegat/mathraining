# -*- coding: utf-8 -*-
require "spec_helper"

describe CategoriesController, type: :controller, category: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:category) { FactoryBot.create(:category) }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_index_behavior(:must_be_connected) }
    it { expect(response).to have_controller_create_behavior('category', :access_refused) }
    it { expect(response).to have_controller_update_behavior(category, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(category, :access_refused) }
  end
  
  context "if the user is an admin but not a root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('category', :access_refused) }
    it { expect(response).to have_controller_update_behavior(category, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(category, :access_refused) }
  end
end
