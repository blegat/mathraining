# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestproblems/show.html.erb", type: :view, contestproblem: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
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
  
  context "if contest is in construction" do
    before do
      contest.in_construction!
      contestproblem.not_started_yet!
    end
    
    context "if the user is an organizer" do
      before { sign_in_view(user_organizer) }
      
      it "renders the page correctly" do
        render template: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        should have_link("Modifier ce problème")
        should have_link("Supprimer ce problème")
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        should have_content("Ce problème n'est pas encore en ligne. Pour modifier sa solution")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
      end
      
      context "if the official solution is asked" do
        before { assign(:contestsolution, contestsolution_official) }
        
        it "renders the page correctly" do
          render template: "contestproblems/show"
          expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution_official})
        end
      end
    end
  end
  
  context "if contest is online but problem not" do
    before do
      contest.in_progress!
      contestproblem.not_started_yet!
    end
    
    context "if the user is an organizer" do
      before { sign_in_view(user_organizer) }
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).to render_template(:partial => "shared/_clock", :locals => {text: "Temps avant publication", date_limit: contestproblem.start_time.to_i, message_zero: "En ligne"})
        should have_link("Modifier ce problème")
        should have_no_link("Supprimer ce problème")
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        should have_content("Ce problème n'est pas encore en ligne. Pour modifier sa solution")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
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
        should have_content("Origine du problème :")
        expect(response).to render_template(:partial => "shared/_clock", :locals => {text: "Temps restant", date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
        should have_link("Modifier ce problème")
        should have_no_link("Supprimer ce problème")
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        should have_content("Ce problème est en train d'être résolu par les participants. Pour modifier sa solution")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
      end
    end
    
    context "if the user can participate" do
      before { sign_in_view(user) }
      
      context "and has not sent a solution yet" do
        before { assign(:contestsolution, Contestsolution.new) }
        
        it "renders the page correctly" do
          render template: "contestproblems/show"
          should have_no_content("Origine du problème :")
          expect(response).to render_template(:partial => "shared/_clock", :locals => {text: "Temps restant", date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
          should have_no_link("Modifier ce problème")
          expect(response).not_to render_template(:partial => "contestsolutions/_index")
          expect(response).to render_template(:partial => "contestsolutions/_new")
          expect(response).not_to render_template(:partial => "contestsolutions/_show")
          should have_no_content("Pour pouvoir participer aux concours, il faut avoir au moins 200 points.")
        end
      end
      
      context "and already sent a solution" do
        let!(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, user: user) }
        
        before {assign(:contestsolution, contestsolution) }
        
        it "renders the page correctly" do
          render template: "contestproblems/show"
          expect(response).not_to render_template(:partial => "contestsolutions/_new")
          expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution})
        end
      end
    end
    
    context "if the user cannot participate" do
      before { sign_in_view(user_bad) }
      
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(response).to render_template(:partial => "shared/_clock", :locals => {text: "Temps restant", date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
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
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        should have_link("Modifier ce problème")
        should have_no_link("Supprimer ce problème")
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        should have_no_content("Ce problème est en train d'être résolu par les participants.")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
      end
    end
    
    context "if the user participated" do
      let!(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, user: user) }
      let!(:contestsolution_other) { FactoryBot.create(:contestsolution, contestproblem: contestproblem) }
      
      before { sign_in_view(user) }    
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
      end
      
      context "if his solution is asked" do
        before { assign(:contestsolution, contestsolution) }
        
        it "shows the solution" do
          render template: "contestproblems/show"
          expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution})
        end
      end
      
      context "if another solution is asked" do
        before { assign(:contestsolution, contestsolution_other) }
        
        it "does not show the solution" do
          render template: "contestproblems/show"
          expect(response).not_to render_template(:partial => "contestsolutions/_show")
        end
      end
      
      context "if the official solution is asked" do
        before { assign(:contestsolution, contestsolution_official) }
        
        it "does not show the solution" do
          render template: "contestproblems/show"
          expect(response).not_to render_template(:partial => "contestsolutions/_show")
        end
      end
    end
  end
  
  context "if contestproblem is corrected" do
    before do
      contest.in_progress!
      contestproblem.corrected!
    end
    
    context "if the user participated" do
      let!(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, user: user, score: 2) }
      let!(:contestsolution_other_good) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, score: 7) }
      let!(:contestsolution_other_bad) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, score: 6) }
      
      before { sign_in_view(user) }      
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
      end
      
      context "if his solution is asked" do
        before { assign(:contestsolution, contestsolution) }
        
        it "shows the solution" do
          render template: "contestproblems/show"
          expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution})
        end
      end
      
      context "if another good solution if asked" do
        before { assign(:contestsolution, contestsolution_other_good) }
        
        it "shows the solution" do
          render template: "contestproblems/show"
          expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution_other_good})
        end
      end
      
      context "does not show another bad solution if asked" do
        before { assign(:contestsolution, contestsolution_other_bad) }
        
        it "does not show the solution" do
          render template: "contestproblems/show"
          expect(response).not_to render_template(:partial => "contestsolutions/_show")
        end
      end
      
      context "if official solution is public" do
        before { contestsolution_official.update_attribute(:score, 7) }
        
        context "if official solution if asked" do
          before { assign(:contestsolution, contestsolution_official) }
          
          it "shows the solution" do
            render template: "contestproblems/show"
            expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution_official})
          end
        end
      end
      
      context "if official solution is not public" do
        before { contestsolution_official.update_attribute(:score, 0) }
        
        context "if official solution if asked" do
          before { assign(:contestsolution, contestsolution_official) }
          
          it "does not show the solution" do
            render template: "contestproblems/show"
            expect(response).not_to render_template(:partial => "contestsolutions/_show")
          end
        end
      end
    end
  end
end
