# -*- coding: utf-8 -*-
require "spec_helper"

describe ProblemsController, type: :controller, problem: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user, rating: 200) }
  let(:section) { FactoryGirl.create(:section) }
  let(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let(:online_problem) { FactoryGirl.create(:problem, online: true) }
  let(:offline_problem) { FactoryGirl.create(:problem, online: false) }
  
  before { online_problem.chapters << chapter }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_show_behavior(online_problem, :must_be_connected) }
    it { expect(response).to have_controller_new_behavior(:must_be_connected, {:section_id => section.id}) }
    it { expect(response).to have_controller_create_behavior('problem', :access_refused, {:section_id => section.id}) }
    it { expect(response).to have_controller_edit_behavior(offline_problem, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(offline_problem, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(offline_problem, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('edit_explanation', offline_problem, :must_be_connected) }
    it { expect(response).to have_controller_patch_path_behavior('update_explanation', offline_problem, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('edit_markscheme', offline_problem, :must_be_connected) }
    it { expect(response).to have_controller_patch_path_behavior('update_markscheme', offline_problem, :access_refused) }
    it { expect(response).to have_controller_post_path_behavior('add_prerequisite', offline_problem, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('delete_prerequisite', offline_problem, :access_refused) }
    it { expect(response).to have_controller_post_path_behavior('add_virtualtest', offline_problem, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('manage_externalsolutions', offline_problem, :must_be_connected) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_show_behavior(offline_problem, :access_refused) }
    it { expect(response).to have_controller_show_behavior(online_problem, :access_refused) } # No access to it
    it { expect(response).to have_controller_new_behavior(:access_refused, {:section_id => section.id}) }
    it { expect(response).to have_controller_create_behavior('problem', :access_refused, {:section_id => section.id}) }
    it { expect(response).to have_controller_edit_behavior(offline_problem, :access_refused) }
    it { expect(response).to have_controller_update_behavior(offline_problem, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(offline_problem, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', offline_problem, :access_refused, {:new_position => 3}) }
    it { expect(response).to have_controller_put_path_behavior('put_online', offline_problem, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('edit_explanation', offline_problem, :access_refused) }
    it { expect(response).to have_controller_patch_path_behavior('update_explanation', offline_problem, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('edit_markscheme', offline_problem, :access_refused) }
    it { expect(response).to have_controller_patch_path_behavior('update_markscheme', offline_problem, :access_refused) }
    it { expect(response).to have_controller_post_path_behavior('add_prerequisite', offline_problem, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('delete_prerequisite', offline_problem, :access_refused) }
    it { expect(response).to have_controller_post_path_behavior('add_virtualtest', offline_problem, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('manage_externalsolutions', online_problem, :access_refused) }
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_destroy_behavior(online_problem, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('put_online', online_problem, :access_refused) }
    it { expect(response).to have_controller_post_path_behavior('add_prerequisite', online_problem, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('delete_prerequisite', online_problem, :access_refused) }
    it { expect(response).to have_controller_post_path_behavior('add_virtualtest', online_problem, :access_refused) }
  end
end
