# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestproblemsController, type: :controller, contestproblem: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:user_organizer) { FactoryBot.create(:advanced_user) }
  let(:user) { FactoryBot.create(:advanced_user) }
  let(:root) { FactoryBot.create(:root) }
  let(:contest) { FactoryBot.create(:contest) }
  let(:contestproblem) { FactoryBot.create(:contestproblem, contest: contest) }
  
  before do
    contest.organizers << user_organizer
  end
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_show_behavior(contestproblem, :must_be_connected) }
    it { expect(response).to have_controller_new_behavior(:must_be_connected, {:contest_id => contest.id}) }
    it { expect(response).to have_controller_create_behavior('contestproblem', :access_refused, {:contest_id => contest.id}) }
    it { expect(response).to have_controller_edit_behavior(contestproblem, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(contestproblem, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(contestproblem, :access_refused) }
  end
  
  context "if the user is not an organizer" do
    before { sign_in_controller(user) }
    
    context "and contest is offline" do
      before do
        contest.in_construction!
        contestproblem.in_construction!
      end
      
      it { expect(response).to have_controller_show_behavior(contestproblem, :access_refused) }
      it { expect(response).to have_controller_new_behavior(:access_refused, {:contest_id => contest.id}) }
      it { expect(response).to have_controller_create_behavior('contestproblem', :access_refused, {:contest_id => contest.id}) }
      it { expect(response).to have_controller_edit_behavior(contestproblem, :access_refused) }
      it { expect(response).to have_controller_update_behavior(contestproblem, :access_refused) }
      it { expect(response).to have_controller_destroy_behavior(contestproblem, :access_refused) }
    end
    
    context "and contest is online but not problem" do
      before do
        contest.in_progress!
        contestproblem.not_started_yet!
      end
      
      it { expect(response).to have_controller_show_behavior(contestproblem, :access_refused) } # Other check in that case
    end
    
    context "and contestproblem is online" do
      before do
        contest.in_progress!
        contestproblem.in_progress!
      end
      
      it { expect(response).to have_controller_show_behavior(contestproblem, :ok) }
    end
  end
  
  context "if the user is an organizer" do
    before { sign_in_controller(user_organizer) }
    
    context "and contest is offline" do
      before do
        contest.in_construction!
        contestproblem.in_construction!
      end
      
      it { expect(response).to have_controller_show_behavior(contestproblem, :ok) }
      it { expect(response).to have_controller_new_behavior(:ok, {:contest_id => contest.id}) }
      it { expect(response).to have_controller_create_behavior('contestproblem', :ok, {:contest_id => contest.id}) }
      it { expect(response).to have_controller_edit_behavior(contestproblem, :ok) }
      it { expect(response).to have_controller_update_behavior(contestproblem, :ok) }
      it { expect(response).to have_controller_destroy_behavior(contestproblem, :ok) }
    end
    
    context "and contest is online but not problem" do
      before do
        contest.in_progress!
        contestproblem.not_started_yet!
      end
      
      it { expect(response).to have_controller_show_behavior(contestproblem, :ok) }
      it { expect(response).to have_controller_new_behavior(:access_refused, {:contest_id => contest.id}) }
      it { expect(response).to have_controller_create_behavior('contestproblem', :access_refused, {:contest_id => contest.id}) }
      it { expect(response).to have_controller_edit_behavior(contestproblem, :ok) }
      it { expect(response).to have_controller_update_behavior(contestproblem, :ok) }
      it { expect(response).to have_controller_destroy_behavior(contestproblem, :access_refused) }
    end
    
    context "and contest problem is in correction" do
      before do
        contest.in_progress!
        contestproblem.in_correction!
      end
      
      it { expect(response).to have_controller_put_path_behavior('publish_results', contestproblem, :danger) } # Because no star solution
      
      context "and there is a star solution" do
        let!(:star_contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, corrected: true, star: true) }
        let!(:subject_contest) { FactoryBot.create(:subject, contest: contest) }
        it { expect(response).to have_controller_put_path_behavior('publish_results', contestproblem, :ok) }
      end
      
      context "and there is a non-corrected solution" do
        let!(:non_corrected_contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, corrected: false) }
        it { expect(response).to have_controller_put_path_behavior('publish_results', contestproblem, :danger) }
      end
    end
    
    context "and contest problem is corrected" do
      before do
        contest.in_progress!
        contestproblem.corrected!
      end
      
      it { expect(response).to have_controller_put_path_behavior('publish_results', contestproblem, :danger) } # Because already corrected
      it { expect(response).to have_controller_put_path_behavior('authorize_corrections', contestproblem, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('unauthorize_corrections', contestproblem, :access_refused) }
    end
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    context "and contest problem is corrected" do
      before do
        contest.in_progress!
        contestproblem.corrected!
      end
      
      it { expect(response).to have_controller_put_path_behavior('authorize_corrections', contestproblem, :ok) }
      it { expect(response).to have_controller_put_path_behavior('unauthorize_corrections', contestproblem, :ok) }
      
      it "redirects to new format when trying to see a solution" do
        get :show, params: {id: contestproblem.id, sol: contestproblem.contestsolutions.where(:official => true).first.id}
        expect(response).to redirect_to contestproblem_contestsolution_path(contestproblem, contestproblem.contestsolutions.where(:official => true).first)
      end
    end
  end
end
