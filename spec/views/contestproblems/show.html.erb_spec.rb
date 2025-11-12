# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestproblems/show.html.erb", type: :view, contestproblem: true do

  subject { rendered }

  let(:user_bad) { FactoryBot.create(:user, rating: 0) }
  let(:user) { FactoryBot.create(:advanced_user) }
  let(:user_organizer) { FactoryBot.create(:user) }
  let(:contest) { FactoryBot.create(:contest) }
  let(:contestproblem) { FactoryBot.create(:contestproblem, contest: contest) }
  let(:contestsolution_official) { contestproblem.contestsolutions.where(:official => true).first }
  
  before do
    contest.organizers << user_organizer
    assign(:contest, contest)
    assign(:contestproblem, contestproblem)
  end
  
  context "if contestproblem is not in progress yet" do
    before do
      contest.in_progress!
      contestproblem.not_started_yet!
    end
    
    context "if the user is an organizer" do
      before { sign_in_view(user_organizer) }
      
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(response).to render_template(:partial => "contestproblems/_show")
        should have_content("Ce problème n'est pas encore en ligne. Pour modifier sa solution")
      end
    end
  end
  
  context "if contestproblem is in progress" do
    before do
      contest.in_progress!
      contestproblem.in_progress!
    end
    
    context "if the user is an organizer" do
      before { sign_in_view(user_organizer) }
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(response).to render_template(:partial => "contestproblems/_show")
        should have_content("Ce problème est en train d'être résolu par les participants. Pour modifier sa solution")
      end
    end
    
    context "if the user is not an organizer" do
      before { sign_in_view(user) }
      
      context "and has not sent a solution yet" do
        before { assign(:contestsolution, Contestsolution.new) }
        
        it "renders the page correctly" do
          render template: "contestproblems/show"
          expect(response).to render_template(:partial => "contestproblems/_show")
          expect(response).to render_template(:partial => "contestsolutions/_show_in_progress")
          expect(response).not_to render_template(:partial => "submissions/_chapters_to_write_submission")
          should have_no_content("Pour pouvoir participer aux concours, il faut avoir au moins 200 points.")
        end
        
        context "and has not solved the latex chapter" do
          let!(:chapter_latex) { FactoryBot.create(:chapter, online: true, submission_prerequisite: true) }
          
          it "renders the page correctly" do
            render template: "contestproblems/show"
            expect(response).not_to render_template(:partial => "contestsolutions/_show_in_progress")
            expect(response).to render_template(:partial => "submissions/_chapters_to_write_submission")
          end
        end
      end
      
      context "and already sent a solution" do
        let!(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, user: user) }
        
        before {assign(:contestsolution, contestsolution) }
        
        it "renders the page correctly" do
          render template: "contestproblems/show"
          expect(response).to render_template(:partial => "contestproblems/_show")
          expect(response).to render_template(:partial => "contestsolutions/_show_in_progress")
          expect(response).not_to render_template(:partial => "submissions/_chapters_to_write_submission")
          should have_no_content("Pour pouvoir participer aux concours, il faut avoir au moins 200 points.")
        end
      end
    end
    
    context "if the user cannot participate" do
      before { sign_in_view(user_bad) }
      
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(response).to render_template(:partial => "contestproblems/_show")
        expect(response).not_to render_template(:partial => "contestsolutions/_show_in_progress")
        expect(response).not_to render_template(:partial => "submissions/_chapters_to_write_submission")
        should have_content("Pour pouvoir participer aux concours, il faut avoir au moins 200 points.")
      end
    end
  end
  
  context "if contestproblem is in correction" do
    before do
      contest.in_progress!
      contestproblem.in_correction!
      contestsolution_official.update_attribute(:score, 7)
    end
    
    context "if the user is an organizer" do
      before { sign_in_view(user_organizer) }
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(response).to render_template(:partial => "contestproblems/_show")
        should have_no_content("Ce problème est en cours de correction.")
        should have_no_content("Ce problème est en train d'être résolu par les participants.")
      end
    end
    
    context "if the user is not an organizer" do      
      before { sign_in_view(user) }    
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(response).to render_template(:partial => "contestproblems/_show")
        should have_content("Ce problème est en cours de correction.")
      end
    end
  end
  
  context "if contestproblem is corrected" do
    before do
      contest.in_progress!
      contestproblem.corrected!
    end
    
    context "if the user is not an organizer" do      
      before { sign_in_view(user) }      
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(response).to render_template(:partial => "contestproblems/_show")
        should have_no_content("Ce problème est en cours de correction.")
      end
    end
  end
end
