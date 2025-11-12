# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestproblems/_show.html.erb", type: :view, contestproblem: true do

  subject { rendered }

  #let(:user_bad) { FactoryBot.create(:user, rating: 0) }
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
        render partial: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        should have_link("Modifier ce problème")
        should have_link("Supprimer ce problème")
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
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
        render partial: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).to render_template(:partial => "shared/_clock", :locals => {text: "Temps avant publication", date_limit: contestproblem.start_time.to_i, message_zero: "En ligne"})
        should have_link("Modifier ce problème")
        should have_no_link("Supprimer ce problème")
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
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
        render partial: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).to render_template(:partial => "shared/_clock", :locals => {text: "Temps restant", date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
        should have_link("Modifier ce problème")
        should have_no_link("Supprimer ce problème")
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
      end
    end
    
    context "if the user is not an organizer" do
      before { sign_in_view(user) }
        
      it "renders the page correctly" do
        render partial: "contestproblems/show"
        should have_no_content("Origine du problème :")
        expect(response).to render_template(:partial => "shared/_clock", :locals => {text: "Temps restant", date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé"})
        should have_no_link("Modifier ce problème")
        expect(response).not_to render_template(:partial => "contestsolutions/_index")
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
        render partial: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        should have_link("Modifier ce problème")
        should have_no_link("Supprimer ce problème")
        expect(response).to render_template(:partial => "contestsolutions/_index")
      end
    end
    
    context "if the user is not an organizer" do
      before { sign_in_view(user) }    
        
      it "renders the page correctly" do
        render partial: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        expect(response).to render_template(:partial => "contestsolutions/_index")
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
        render partial: "contestproblems/show"
        should have_content("Origine du problème :")
        expect(response).not_to render_template(:partial => "shared/_clock")
        expect(response).to render_template(:partial => "contestsolutions/_index")
      end
    end
  end
end
