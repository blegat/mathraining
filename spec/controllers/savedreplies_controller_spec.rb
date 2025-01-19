# -*- coding: utf-8 -*-
require "spec_helper"

describe SavedrepliesController, type: :controller, savedreply: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:root) { FactoryGirl.create(:root) }
  let(:submission) { FactoryGirl.create(:submission) }
  let(:savedreply) { FactoryGirl.create(:savedreply) }
  
  context "if the user is not a corrector" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_show_behavior(savedreply, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:access_refused, {:sub => submission}) }
    it { expect(response).to have_controller_create_behavior('savedreply', :access_refused, {:sub => submission}) }
    it { expect(response).to have_controller_edit_behavior(savedreply, :access_refused, {:sub => submission}) }
    it { expect(response).to have_controller_update_behavior(savedreply, :access_refused, {:sub => submission}) }
    it { expect(response).to have_controller_destroy_behavior(savedreply, :access_refused) }
  end
  
  context "if the user is not an root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_show_behavior(savedreply, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:ok, {:sub => submission}) }
    it { expect(response).to have_controller_create_behavior('savedreply', :ok, {:sub => submission}) }
    it { expect(response).to have_controller_edit_behavior(savedreply, :access_refused, {:sub => submission}) }
    it { expect(response).to have_controller_update_behavior(savedreply, :access_refused, {:sub => submission}) }
    it { expect(response).to have_controller_destroy_behavior(savedreply, :access_refused) }
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_show_behavior(savedreply, :ok) }
    it { expect(response).to have_controller_new_behavior(:ok, {:sub => submission}) }
    it { expect(response).to have_controller_create_behavior('savedreply', :ok, {:sub => submission}) }
    it { expect(response).to have_controller_edit_behavior(savedreply, :ok, {:sub => submission}) }
    it { expect(response).to have_controller_update_behavior(savedreply, :ok, {:sub => submission}) }
    it { expect(response).to have_controller_destroy_behavior(savedreply, :ok) }
  end
end
