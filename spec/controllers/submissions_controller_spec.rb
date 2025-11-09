# -*- coding: utf-8 -*-
require "spec_helper"

describe SubmissionsController, type: :controller, submission: true do

  let(:chapter) { FactoryBot.create(:chapter, online: true) }
  let(:problem) { FactoryBot.create(:problem, online: true) }
  
  let(:user1) { FactoryBot.create(:advanced_user) }
  let(:user2) { FactoryBot.create(:advanced_user) }
  let(:bad_user) { FactoryBot.create(:advanced_user) }
  let(:good_corrector) { FactoryBot.create(:corrector) }
  let(:bad_corrector) { FactoryBot.create(:corrector) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:root) { FactoryBot.create(:root) }
  
  let(:submission_draft) { FactoryBot.create(:submission, problem: problem, user: user1, status: :draft) }
  let(:submission_wrong) { FactoryBot.create(:submission, problem: problem, user: user1, status: :wrong) }
  let(:submission_correct) { FactoryBot.create(:submission, problem: problem, user: user2, status: :correct) }
  let!(:sp1) { FactoryBot.create(:solvedproblem, problem: problem, user: user2) }
  let!(:sp2) { FactoryBot.create(:solvedproblem, problem: problem, user: good_corrector) }
  
  before do
    problem.chapters << chapter
    user1.chapters << chapter
    user2.chapters << chapter
    good_corrector.chapters << chapter
    bad_corrector.chapters << chapter
  end
  
  context "if the user did not solve the prerequisite" do
    before { sign_in_controller(bad_user) }
    
     it { expect(response).to have_controller_create_behavior('submission', :access_refused, {:problem_id => problem.id}) }
  end
  
  context "if the user is a simple user (1)" do
    before { sign_in_controller(user1) }
      
    it { expect(response).to have_controller_create_behavior('submission', :ok, {:problem_id => problem.id}) } # Allowed but update will be triggered automatically
    it { expect(response).to have_controller_update_behavior(submission_draft, :ok) }
    it { expect(response).to have_controller_update_behavior(submission_wrong, :danger) } # Not allowed but smooth redirect
    it { expect(response).to have_controller_destroy_behavior(submission_draft, :ok) }
    it { expect(response).to have_controller_destroy_behavior(submission_wrong, :danger) } # Not allowed but smooth redirect
    it { expect(response).to have_controller_put_path_behavior('send_draft', submission_draft, :ok) }
    it { expect(response).to have_controller_put_path_behavior('send_draft', submission_wrong, :danger) } # Not allowed but smooth redirect
    it { expect(response).to have_controller_put_path_behavior('read', submission_wrong, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unread', submission_wrong, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('all', :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('allnew', :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('allmy', :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('allmynew', :access_refused) }
  end
  
  context "if the user is a simple user (2)" do
    before { sign_in_controller(user2) }
    
    it { expect(response).to have_controller_update_behavior(submission_draft, :access_refused) } # Not his solution
    it { expect(response).to have_controller_destroy_behavior(submission_draft, :access_refused) } # Not his solution
    it { expect(response).to have_controller_put_path_behavior('send_draft', submission_draft, :access_refused) } # Not his solution
  end
  
  context "if the user is a bad corrector" do
    before { sign_in_controller(bad_corrector) }
    
    it { expect(response).to have_controller_put_path_behavior('read', submission_wrong, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unread', submission_wrong, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('mark_wrong', submission_correct, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('mark_correct', submission_wrong, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('all', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allnew', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allmy', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allmynew', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allhidden', :access_refused) }
  end
  
  context "if the user is a good corrector" do
    before { sign_in_controller(good_corrector) }
    
    it { expect(response).to have_controller_put_path_behavior('read', submission_wrong, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unread', submission_wrong, :ok) }
    it { expect(response).to have_controller_put_path_behavior('star', submission_correct, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unstar', submission_correct, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('update_score', submission_correct, :access_refused, {:new_score => 7}) }
    it { expect(response).to have_controller_put_path_behavior('mark_wrong', submission_correct, :danger) } # Danger message because of wrong timing
    it { expect(response).to have_controller_put_path_behavior('mark_correct', submission_wrong, :danger) } # Danger message because of wrong timing
  end
  
  context "if the user is a admin" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_create_behavior('submission', :access_refused, {:problem_id => problem.id}) }
    it { expect(response).to have_controller_update_behavior(submission_correct, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(submission_wrong, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('read', submission_wrong, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unread', submission_wrong, :ok) }
    it { expect(response).to have_controller_put_path_behavior('star', submission_correct, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unstar', submission_correct, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('update_score', submission_correct, :access_refused, {:new_score => 7}) }
    it { expect(response).to have_controller_put_path_behavior('mark_wrong', submission_correct, :danger) } # Danger message because of wrong timing
    it { expect(response).to have_controller_put_path_behavior('mark_correct', submission_wrong, :danger) } # Danger message because of wrong timing
    it { expect(response).to have_controller_get_static_path_behavior('all', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allnew', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allmy', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allmynew', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('allhidden', :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('next_good', submission_correct, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('prev_good', submission_correct, :access_refused) }
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    it { expect(response).to have_controller_update_behavior(submission_correct, :ok) }
    it { expect(response).to have_controller_destroy_behavior(submission_wrong, :ok) }
    it { expect(response).to have_controller_put_path_behavior('star', submission_correct, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unstar', submission_correct, :ok) }
    it { expect(response).to have_controller_put_path_behavior('update_score', submission_correct, :ok, {:new_score => 7}) }
    it { expect(response).to have_controller_get_static_path_behavior('allhidden', :ok) }
    it { expect(response).to have_controller_put_path_behavior('mark_wrong', submission_correct, :ok) } # Root can always mark as wrong
    it { expect(response).to have_controller_put_path_behavior('mark_correct', submission_wrong, :danger) } # Danger message because of wrong timing
    it { expect(response).to have_controller_put_path_behavior('next_good', submission_correct, :ok) }
    it { expect(response).to have_controller_put_path_behavior('prev_good', submission_correct, :ok) }
  end
end


