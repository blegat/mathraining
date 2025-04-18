# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestsController, type: :controller, contest: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:user_organizer) { FactoryBot.create(:advanced_user) }
  let(:user) { FactoryBot.create(:advanced_user) }
  let(:contest) { FactoryBot.create(:contest) }
  
  before do
    contest.organizers << user_organizer
  end
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_index_behavior(:ok) }
    
    context "and contest is offline" do
      before { contest.in_construction! }
      
      it { expect(response).to have_controller_show_behavior(contest, :access_refused) }
      it { expect(response).to have_controller_new_behavior(:must_be_connected) }
      it { expect(response).to have_controller_create_behavior('contest', :access_refused) }
      it { expect(response).to have_controller_edit_behavior(contest, :must_be_connected) }
      it { expect(response).to have_controller_update_behavior(contest, :access_refused) }
      it { expect(response).to have_controller_destroy_behavior(contest, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('follow', contest, :access_refused) }
      it { expect(response).to have_controller_get_path_behavior('unfollow', contest, :must_be_connected) }
    end
    
    context "and contest is online" do
      before { contest.in_progress! }
      
      it { expect(response).to have_controller_show_behavior(contest, :ok) }
    end
  end
  
  context "if the user is not an organizer" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_edit_behavior(contest, :access_refused) }
    it { expect(response).to have_controller_update_behavior(contest, :access_refused) }
    
    context "and contest is offline" do
      before { contest.in_construction! }
      
      it { expect(response).to have_controller_show_behavior(contest, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('follow', contest, :access_refused) }
      it { expect(response).to have_controller_get_path_behavior('unfollow', contest, :access_refused) }
    end
    
    context "and contest is online" do
      before { contest.in_progress! }
      
      it { expect(response).to have_controller_show_behavior(contest, :ok) }
      it { expect(response).to have_controller_put_path_behavior('follow', contest, :ok) }
      it { expect(response).to have_controller_get_path_behavior('unfollow', contest, :ok) }
    end
    
    context "and cutoffs can be defined by organizers" do
      before do
        contest.update_attribute(:medal, true)
        contest.completed!
      end
      
      it { expect(response).to have_controller_get_path_behavior('cutoffs', contest, :access_refused) }
      it { expect(response).to have_controller_post_path_behavior('define_cutoffs', contest, :access_refused, {:bronze_cutoff => 1, :silver_cutoff => 2, :gold_cutoff => 3}) }
    end
  end
  
  context "if the user is an organizer" do
    before { sign_in_controller(user_organizer) }
    
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('contest', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(contest, :ok) }
    it { expect(response).to have_controller_update_behavior(contest, :ok) }
    it { expect(response).to have_controller_destroy_behavior(contest, :access_refused) }
    it { expect(response).to have_controller_patch_path_behavior('add_organizer', contest, :access_refused, {:user_id => admin.id}) }
    it { expect(response).to have_controller_put_path_behavior('remove_organizer', contest, :access_refused, {:user_id => user_organizer.id}) }
    
    context "and contest is offline" do
      before { contest.in_construction! }
      
      it { expect(response).to have_controller_put_path_behavior('put_online', contest, :access_refused) }
    end
    
    context "and medals are already distributed" do
      before do
        contest.update(medal: true, bronze_cutoff: 1, silver_cutoff: 2, gold_cutoff: 3)
        contest.completed!
      end
      
      it { expect(response).to have_controller_get_path_behavior('cutoffs', contest, :access_refused) }
      it { expect(response).to have_controller_post_path_behavior('define_cutoffs', contest, :access_refused, {:bronze_cutoff => 1, :silver_cutoff => 2, :gold_cutoff => 3}) }
    end
    
    context "and no medals can be given" do
      before do
        contest.update(medal: false, bronze_cutoff: 0, silver_cutoff: 0, gold_cutoff: 0)
        contest.completed!
      end
      
      it { expect(response).to have_controller_get_path_behavior('cutoffs', contest, :access_refused) }
      it { expect(response).to have_controller_post_path_behavior('define_cutoffs', contest, :access_refused, {:bronze_cutoff => 1, :silver_cutoff => 2, :gold_cutoff => 3}) }
    end
    
    context "and contest is not completed" do
      before do
        contest.update(medal: true, bronze_cutoff: 0, silver_cutoff: 0, gold_cutoff: 0)
        contest.in_correction!
      end
      
      it { expect(response).to have_controller_get_path_behavior('cutoffs', contest, :access_refused) }
      it { expect(response).to have_controller_post_path_behavior('define_cutoffs', contest, :access_refused, {:bronze_cutoff => 1, :silver_cutoff => 2, :gold_cutoff => 3}) }
    end
    
    context "and medals can be distributed" do
      before do
        contest.update(medal: true)
        contest.completed!
      end
      
      it { expect(response).to have_controller_get_path_behavior('cutoffs', contest, :ok) }
      it { expect(response).to have_controller_post_path_behavior('define_cutoffs', contest, :ok, {:bronze_cutoff => 1, :silver_cutoff => 2, :gold_cutoff => 3}) }
    end
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    context "and contest is online" do
      before { contest.in_progress! }
      
      it { expect(response).to have_controller_destroy_behavior(contest, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('put_online', contest, :access_refused) }
    end
  end
end
