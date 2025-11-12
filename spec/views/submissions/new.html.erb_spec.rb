# -*- coding: utf-8 -*-
require "spec_helper"

describe "submissions/new.html.erb", type: :view, submission: true do

  subject { rendered }

  let(:bad_user) { FactoryBot.create(:advanced_user) }
  let(:good_user) { FactoryBot.create(:advanced_user) }
  let(:chapter) { FactoryBot.create(:chapter, online: true) }
  let!(:problem) { FactoryBot.create(:problem, online: true, explanation: "Voici la solution") }
  let!(:user_submission) { FactoryBot.create(:submission, user: good_user, problem: problem, status: :correct) }
  let!(:user_sp) { FactoryBot.create(:solvedproblem, user: good_user, problem: problem, submission: user_submission) }
  let!(:new_submission) { Submission.new }
  
  before do
    assign(:problem, problem)
    assign(:submission, new_submission)
    bad_user.chapters << chapter
    good_user.chapters << chapter
  end
  
  context "if the user didn't solve the problem" do
    before { sign_in_view(bad_user) }
    
    context "and tries to write a new submission" do
      it "renders the form correctly" do
        render template: "submissions/new"
        expect(response).to render_template(:partial => "problems/_show", :locals => {show_new_button: false})
        expect(response).to render_template(:partial => "submissions/_show_before_send")
        expect(response).not_to render_template(:partial => "submissions/_chapters_to_write_submission")
      end
    end
    
    context "and tries to write a new submission without knowing LaTeX" do
      let!(:latex_chapter) { FactoryBot.create(:chapter, online: true, submission_prerequisite: true) }
      
      it "renders the message correctly" do
        render template: "submissions/new"
        expect(response).to render_template(:partial => "problems/_show", :locals => {show_new_button: false})
        expect(response).not_to render_template(:partial => "submissions/_show_before_send")
        expect(response).to render_template(:partial => "submissions/_chapters_to_write_submission")
      end
    end
    
    context "and has a plagiarized submission" do
      let!(:plagiarized_submission) { FactoryBot.create(:submission, problem: problem, user: bad_user, status: :plagiarized, last_comment_time: DateTime.now - 3.months) }
      
      it "does not render the form" do
        render template: "submissions/new"
        expect(response).to render_template(:partial => "problems/_show", :locals => {show_new_button: false})
        expect(response).not_to render_template(:partial => "submissions/_show_before_send")
        expect(response).not_to render_template(:partial => "submissions/_chapters_to_write_submission")
      end
    end
  end
  
  context "if the user solved the problem" do
    before { sign_in_view(good_user) }
    
    context "and tries to write a new submission" do
      let!(:new_submission) { Submission.new }
      before { assign(:submission, new_submission) }
      
      it "does not render the form" do
        render template: "submissions/new"
        expect(response).to render_template(:partial => "problems/_show", :locals => {show_new_button: false})
        expect(response).not_to render_template(:partial => "submissions/_show_before_send")
        expect(response).not_to render_template(:partial => "submissions/_chapters_to_write_submission")
      end
    end
  end
end
