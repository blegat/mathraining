# -*- coding: utf-8 -*-
require "spec_helper"

describe "contests/_problems.html.erb", type: :view, contest: true do

  subject { rendered }

  let(:user) { FactoryGirl.create(:user) }
  let(:user_organizer) { FactoryGirl.create(:user) }
  let!(:contest) { FactoryGirl.create(:contest) }
  let!(:contestproblem) { FactoryGirl.create(:contestproblem, contest: contest) }
  
  before do
    contest.organizers << user_organizer
    assign(:contest, contest)
  end
  
  context "if the contest is in construction" do
    before do
      contest.in_construction!
      contestproblem.in_construction!
    end
    
    context "and the user is an organizer" do
      before { sign_in_view(user_organizer) }
    
      it "renders the contestproblem correctly" do
        render partial: "contests/problems"
        should have_selector("table", class: "greyy")
        should have_link("Problème ##{contestproblem.number}", href: contestproblem_path(contestproblem))
        should have_content(contestproblem.statement)
        should have_content(contestproblem.origin)
        should have_no_content("Tenté par")
        should have_no_content("Publication dans :")
        expect(response).not_to render_template(:partial => "contests/_clock")
      end
    end
  end
  
  context "if the contestproblem is not online yet" do
    before do
      contest.in_progress!
      contestproblem.not_started_yet!
    end
    
    context "and the user is an organizer" do
      before { sign_in_view(user_organizer) }
    
      it "renders the contestproblem correctly" do
        render partial: "contests/problems"
        should have_selector("table", class: "greyy")
        should have_link("Problème ##{contestproblem.number}", href: contestproblem_path(contestproblem))
        should have_content(contestproblem.statement)
        should have_content(contestproblem.origin)
        should have_no_content("Tenté par")
        should have_content("Publication dans :")
        expect(response).to render_template(:partial => "contests/_clock", :locals => {date_limit: contestproblem.start_time.to_i, message_zero: "En ligne", p_id: contestproblem.id})
      end
    end
    
    context "and the user is a participant" do
      before { sign_in_view(user) }
    
      it "renders the contestproblem correctly" do
        render partial: "contests/problems"
        should have_selector("table", class: "greyy")
        should have_no_link("Problème ##{contestproblem.number}", href: contestproblem_path(contestproblem))
        should have_selector("h4", text: "Problème ##{contestproblem.number}")
        should have_no_content(contestproblem.statement)
        should have_no_content(contestproblem.origin)
      end
    end
  end
  
  context "if the contestproblem is in progress" do
    before do
      contest.in_progress!
      contestproblem.in_progress!
    end
    
    context "and the user is an organizer" do
      before { sign_in_view(user_organizer) }
    
      it "renders the contestproblem correctly" do
        render partial: "contests/problems"
        should have_selector("table", class: "orangey")
        should have_link("Problème ##{contestproblem.number}", href: contestproblem_path(contestproblem))
        should have_content(contestproblem.statement)
        should have_content(contestproblem.origin)
        should have_content("Tenté par 0 personne")
        should have_content("Temps restant :")
        expect(response).to render_template(:partial => "contests/_clock", :locals => {date_limit: contestproblem.end_time.to_i, message_zero: "Temps écoulé", p_id: contestproblem.id})
      end
    end
    
    context "and the user is a participant" do
      before { sign_in_view(user) }
    
      it "renders the contestproblem correctly" do
        render partial: "contests/problems"
        should have_selector("table", class: "orangey")
        should have_link("Problème ##{contestproblem.number}", href: contestproblem_path(contestproblem))
        should have_content(contestproblem.statement)
        should have_no_content(contestproblem.origin)
      end
    end
  end
  
  context "if the contestproblem is in correction" do
    before do
      contest.in_correction!
      contestproblem.in_correction!
      FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false, score: -1)
    end
    
    context "and the user is a participant" do
      before { sign_in_view(user) }
    
      it "renders the contestproblem correctly" do
        render partial: "contests/problems"
        should have_selector("table", class: "yellowy")
        should have_link("Problème ##{contestproblem.number}", href: contestproblem_path(contestproblem))
        should have_content(contestproblem.statement)
        should have_content(contestproblem.origin)
        should have_content("Tenté par 1 personne")
        should have_content("En cours de correction")
        should have_no_content("Temps restant :")
      end
    end
  end
  
  context "if the contestproblem is corrected" do
    before do
      contest.completed!
      contestproblem.corrected!
      FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false, corrected: true, score: 7)
      FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false, corrected: true, score: 4)
    end
    
    context "and the user is a participant" do
      before { sign_in_view(user) }
    
      it "renders the contestproblem correctly" do
        render partial: "contests/problems"
        should have_selector("table", class: "yellowy")
        should have_link("Problème ##{contestproblem.number}", href: contestproblem_path(contestproblem))
        should have_content(contestproblem.statement)
        should have_content(contestproblem.origin)
        should have_content("Tenté par 2 personnes")
        should have_content("Scores parfaits : 1")
        should have_no_content("Temps restant :")
      end
    end
  end
end
