# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestproblems/show.html.erb", type: :view, contestproblem: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_bad) { FactoryGirl.create(:user, rating: 0) }
  let(:user) { FactoryGirl.create(:advanced_user) }
  let(:user_organizer) { FactoryGirl.create(:user) }
  let(:contest) { FactoryGirl.create(:contest) }
  let(:contestproblem) { FactoryGirl.create(:contestproblem, contest: contest) }
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
      before do
        assign(:signed_in, true)
        assign(:current_user, user_organizer)
      end
      
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(rendered).to have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "contests/_clock")
        expect(rendered).to have_link("Modifier ce problème")
        expect(rendered).to have_link("Supprimer ce problème")
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(rendered).to have_content("Ce problème n'est pas encore en ligne. Pour modifier sa solution")
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
      before do
        assign(:signed_in, true)
        assign(:current_user, user_organizer)
      end
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(rendered).to have_content("Origine du problème :")
        expect(rendered).to have_content("Temps avant publication :")
        expect(response).to render_template(:partial => "contests/_clock", :locals => {date_limit: contestproblem.start_time.to_i, message_zero: "En ligne"})
        expect(rendered).to have_link("Modifier ce problème")
        expect(rendered).to have_no_link("Supprimer ce problème")
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(rendered).to have_content("Ce problème n'est pas encore en ligne. Pour modifier sa solution")
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
      before do
        assign(:signed_in, true)
        assign(:current_user, user_organizer)
      end
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(rendered).to have_content("Origine du problème :")
        expect(rendered).to have_no_content("Temps avant publication :")
        expect(rendered).to have_content("Temps restant :")
        expect(response).to render_template(:partial => "contests/_clock", :locals => {date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
        expect(rendered).to have_link("Modifier ce problème")
        expect(rendered).to have_no_link("Supprimer ce problème")
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(rendered).to have_content("Ce problème est en train d'être résolu par les participants. Pour modifier sa solution")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
      end
    end
    
    context "if the user can participate" do
      before do
        assign(:signed_in, true)
        assign(:current_user, user)
      end
      
      context "and has not sent a solution yet" do
        before { assign(:contestsolution, Contestsolution.new) }
        it "renders the page correctly" do
          render template: "contestproblems/show"
          expect(rendered).to have_no_content("Origine du problème :")
          expect(rendered).to have_content("Temps restant :")
          expect(response).to render_template(:partial => "contests/_clock", :locals => {date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
          expect(rendered).to have_no_link("Modifier ce problème")
          expect(response).to render_template(:partial => "contestsolutions/_index")
          expect(response).to render_template(:partial => "contestsolutions/_new")
          expect(response).not_to render_template(:partial => "contestsolutions/_show")
          expect(rendered).to have_no_content("Pour pouvoir participer aux concours, il faut avoir au moins 200 points.")
        end
      end
      
      context "and already sent a solution" do
        let!(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, user: user) }
        
        before {assign(:contestsolution, contestsolution) }
        it "renders the page correctly" do
          render template: "contestproblems/show"
          expect(response).not_to render_template(:partial => "contestsolutions/_new")
          expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution})
        end
      end
    end
    
    context "if the user cannot participate" do
      before do
        assign(:signed_in, true)
        assign(:current_user, user_bad)
      end
      
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(rendered).to have_content("Temps restant :")
        expect(response).to render_template(:partial => "contests/_clock", :locals => {date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
        expect(rendered).to have_content("Pour pouvoir participer aux concours, il faut avoir au moins 200 points.")
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
      before do
        assign(:signed_in, true)
        assign(:current_user, user_organizer)
      end
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(rendered).to have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "contests/_clock")
        expect(rendered).to have_link("Modifier ce problème")
        expect(rendered).to have_no_link("Supprimer ce problème")
        expect(response).to render_template(:partial => "contestsolutions/_index")
        expect(response).not_to render_template(:partial => "contestsolutions/_new")
        expect(rendered).to have_no_content("Ce problème est en train d'être résolu par les participants.")
        expect(response).not_to render_template(:partial => "contestsolutions/_show")
      end
    end
    
    context "if the user participated" do
      let!(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, user: user) }
      let!(:contestsolution_other) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem) }
      before do
        assign(:signed_in, true)
        assign(:current_user, user)
      end       
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(rendered).to have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "contests/_clock")
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
      let!(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, user: user, score: 2) }
      let!(:contestsolution_other_good) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, score: 7) }
      let!(:contestsolution_other_bad) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, score: 6) }
      before do
        assign(:signed_in, true)
        assign(:current_user, user)
      end       
        
      it "renders the page correctly" do
        render template: "contestproblems/show"
        expect(rendered).to have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "contests/_clock")
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
        before do
          contestsolution_official.update_attribute(:score, 7)
        end
        
        context "if official solution if asked" do
          before { assign(:contestsolution, contestsolution_official) }
          it "shows the solution" do
            render template: "contestproblems/show"
            expect(response).to render_template(:partial => "contestsolutions/_show", :locals => {contestsolution: contestsolution_official})
          end
        end
      end
      
      context "if official solution is not public" do
        before do
          contestsolution_official.update_attribute(:score, 0)
        end
        
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
