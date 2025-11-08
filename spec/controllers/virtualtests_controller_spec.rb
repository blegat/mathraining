# -*- coding: utf-8 -*-
require "spec_helper"

describe VirtualtestsController, :type => :controller, virtualtest: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:advanced_user) }
  
  let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true) }
  let!(:problem) { FactoryBot.create(:problem, online: true,  virtualtest: virtualtest) }
  let!(:chapter) { FactoryBot.create(:chapter, online: true) }
  let!(:offline_virtualtest) { FactoryBot.create(:virtualtest, online: false) }
  let!(:problem2) { FactoryBot.create(:problem, online: true, virtualtest: offline_virtualtest) }
  
  before { problem.chapters << chapter }
  
  describe "if the user is not signed in" do
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_show_behavior(virtualtest, :must_be_connected) }
  end
  
  describe "if the user has not enough points" do
    before do
      sign_in_controller user
      user.update_attribute(:rating, 199)
    end
    
    it { expect(response).to have_controller_put_path_behavior('begin_test', virtualtest, :access_refused) }
  end
  
  describe "if the user has not completed the prerequisite" do
    before { sign_in_controller user }
    
    it { expect(response).to have_controller_put_path_behavior('begin_test', virtualtest, :access_refused) }
  end
  
  describe "if the user has completed the prerequisite" do
    before do
      sign_in_controller user
      user.chapters << chapter
    end
    
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_show_behavior(virtualtest, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('virtualtest', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(offline_virtualtest, :access_refused) }
    it { expect(response).to have_controller_update_behavior(offline_virtualtest, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(offline_virtualtest, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('put_online', offline_virtualtest, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('begin_test', virtualtest, :ok) }
    
    describe "and has started the test" do
      before { Takentest.create(virtualtest: virtualtest, user: user, taken_time: DateTime.now - 2.minutes, status: :in_progress) }
      
      it { expect(response).to have_controller_show_behavior(virtualtest, :ok) }
    end
  end
  
  describe "if the user is an admin" do
    before { sign_in_controller admin }
    
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_show_behavior(virtualtest, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:ok) }
    it { expect(response).to have_controller_create_behavior('virtualtest', :ok) }
    it { expect(response).to have_controller_edit_behavior(offline_virtualtest, :ok) }
    it { expect(response).to have_controller_edit_behavior(virtualtest, :access_refused) }
    it { expect(response).to have_controller_update_behavior(offline_virtualtest, :ok) }
    it { expect(response).to have_controller_update_behavior(virtualtest, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(offline_virtualtest, :ok) }
    it { expect(response).to have_controller_destroy_behavior(virtualtest, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('put_online', offline_virtualtest, :ok) }
    it { expect(response).to have_controller_put_path_behavior('begin_test', virtualtest, :access_refused) }
  end
end
