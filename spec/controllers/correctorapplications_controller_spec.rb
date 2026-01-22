# -*- coding: utf-8 -*-
require "spec_helper"

describe CorrectorapplicationsController, type: :controller, correctorapplication: true do

  let(:user_bad) { FactoryBot.create(:user, rating: 4000) }
  let(:user) { FactoryBot.create(:user, rating: 6000) }
  let(:corrector) { FactoryBot.create(:corrector, rating: 8000) }
  let(:root) { FactoryBot.create(:root) }
  let(:correctorapplication) { FactoryBot.create(:correctorapplication) }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_index_behavior(:must_be_connected) }
    it { expect(response).to have_controller_new_behavior(:ok) }
    it { expect(response).to have_controller_show_behavior(correctorapplication, :must_be_connected) }
    it { expect(response).to have_controller_create_behavior('correctorapplication', :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(correctorapplication, :access_refused) }
    it { expect(response).to have_controller_patch_path_behavior('answer', correctorapplication, :access_refused) }
  end
  
  context "if the user could be corrector" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_new_behavior(:ok) }
    it { expect(response).to have_controller_show_behavior(correctorapplication, :access_refused) }
    it { expect(response).to have_controller_create_behavior('correctorapplication', :ok) }
    it { expect(response).to have_controller_destroy_behavior(correctorapplication, :access_refused) }
    it { expect(response).to have_controller_patch_path_behavior('answer', correctorapplication, :access_refused) }
  end
  
  context "if the user has low rating" do
    before { sign_in_controller(user_bad) }
    
    it { expect(response).to have_controller_create_behavior('correctorapplication', :access_refused) }
  end
  
  context "if the user is already corrector" do
    before { sign_in_controller(corrector) }
    
    it { expect(response).to have_controller_create_behavior('correctorapplication', :access_refused) }
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_new_behavior(:ok) }
    it { expect(response).to have_controller_show_behavior(correctorapplication, :ok) }
    it { expect(response).to have_controller_create_behavior('correctorapplication', :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(correctorapplication, :ok) }
    it { expect(response).to have_controller_patch_path_behavior('answer', correctorapplication, :ok, {correctorapplication: {answer: "C'est oui !"}}) }
  end
end
