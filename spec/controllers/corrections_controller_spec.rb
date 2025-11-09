# -*- coding: utf-8 -*-
require "spec_helper"

describe CorrectionsController, type: :controller, correction: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:problem) { FactoryBot.create(:problem, online: true) }
  let(:submission) { FactoryBot.create(:submission, problem: problem, user: user) }
  
  context "if the user is the author of the submission" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_create_behavior('correction', :ok, {:submission_id => submission.id}) }
    
    context "but the submission is waiting in a test" do
      before { submission.update(:intest => true, :status => :waiting) }
    
      it { expect(response).to have_controller_create_behavior('correction', :access_refused, {:submission_id => submission.id}) }
    end
    
    context "but the submission is too old" do
      before { submission.update(:last_comment_time => DateTime.now - 3.months, :status => :wrong) }
    
      it { expect(response).to have_controller_create_behavior('correction', :danger, {:submission_id => submission.id}) }
    end
    
    context "but user has a recent sanction" do
      let!(:sanction) { FactoryBot.create(:sanction, user: user, sanction_type: :no_submission, start_time: DateTime.now - 21.days, duration: 23) }
      
       it { expect(response).to have_controller_create_behavior('correction', :danger, {:submission_id => submission.id}) }
    end
    
    context "but user has an old sanction" do
      let!(:sanction) { FactoryBot.create(:sanction, user: user, sanction_type: :no_submission, start_time: DateTime.now - 28.days, duration: 23) }
      
       it { expect(response).to have_controller_create_behavior('correction', :ok, {:submission_id => submission.id}) }
    end
    
    context "but user has another recently closed submission" do
      let!(:other_sub) { FactoryBot.create(:submission, user: user, problem: problem, created_at: DateTime.now - 5.days, status: :closed) }
    
      it { expect(response).to have_controller_create_behavior('correction', :danger, {:submission_id => submission.id}) }
    end
    
    context "but user has another old closed submission" do
      let!(:other_sub) { FactoryBot.create(:submission, user: user, problem: problem, created_at: DateTime.now - 13.days, status: :closed) }
    
      it { expect(response).to have_controller_create_behavior('correction', :ok, {:submission_id => submission.id}) }
    end
    
    context "but user has another recently plagiarized submission" do
      let!(:other_sub) { FactoryBot.create(:submission, user: user, problem: problem, created_at: DateTime.now - 5.months, status: :plagiarized) }
    
      it { expect(response).to have_controller_create_behavior('correction', :danger, {:submission_id => submission.id}) }
    end
    
    context "but user has another old plagiarized submission" do
      let!(:other_sub) { FactoryBot.create(:submission, user: user, problem: problem, created_at: DateTime.now - 8.months, status: :plagiarized) }
    
      it { expect(response).to have_controller_create_behavior('correction', :ok, {:submission_id => submission.id}) }
    end
  end
  
  context "if the user is not involved in submission" do
    before { sign_in_controller(other_user) }
    
    it { expect(response).to have_controller_create_behavior('correction', :access_refused, {:submission_id => submission.id}) }
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_create_behavior('correction', :ok, {:submission_id => submission.id}) }
    
    context "but the submission is a draft" do
      before { submission.draft! }
      
      it { expect(response).to have_controller_create_behavior('correction', :access_refused, {:submission_id => submission.id}) }
    end
    
    context "but the submission is plagiarized" do
      before { submission.plagiarized! }
      
      it { expect(response).to have_controller_create_behavior('correction', :danger, {:submission_id => submission.id}) }
    end
  end
end
