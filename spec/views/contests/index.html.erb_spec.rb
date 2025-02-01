# -*- coding: utf-8 -*-
require "spec_helper"

describe "contests/index.html.erb", type: :view, contest: true do

  subject { rendered }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_bad) { FactoryGirl.create(:user) }
  let(:user) { FactoryGirl.create(:advanced_user) }
  let(:user2) { FactoryGirl.create(:advanced_user) }
  let(:user_organizer) { FactoryGirl.create(:user) }
  let!(:contest) { FactoryGirl.create(:contest, num_problems: 2) }
  let!(:contestproblem1) { FactoryGirl.create(:contestproblem, contest: contest) }
  let!(:contestproblem2) { FactoryGirl.create(:contestproblem, contest: contest) }
  
  before do
    contest.organizers << user_organizer
    assign(:contest, contest)
  end
  
  context "if the contest is in construction" do
    before do
      contest.in_construction!
      contestproblem1.in_construction!
      contestproblem2.in_construction!
    end
    
    context "if the user is an admin" do
      before { sign_in_view(admin) }
        
      it "renders the contest correctly" do
        render template: "contests/index"
        should have_selector("table", class: "greyy")
        should have_link("Concours ##{contest.number}", href: contest_path(contest))
        should have_content("(à venir)")
        should have_content("Aucun problème corrigé")
        should have_link("Ajouter un concours")
      end
    end
    
    context "if the user is an organizer" do
      before { sign_in_view(user_organizer) }
        
      it "renders the contest correctly" do
        render template: "contests/index"
        should have_selector("table", class: "greyy")
        should have_link("Concours ##{contest.number}", href: contest_path(contest))
        should have_content("(à venir)")
        should have_content("Aucun problème corrigé")
        should have_no_link("Ajouter un concours")
      end
    end
    
    context "if the user is not an organizer" do
      before { sign_in_view(user_bad) }
        
      it "does not render the contest" do
        render template: "contests/index"
        should have_no_selector("table", class: "greyy")
        should have_no_link("Concours ##{contest.number}", href: contest_path(contest))
      end
    end
  end
  
  context "if the contest is not started yet" do
    before do
      contest.in_progress!
      contestproblem1.not_started_yet!
      contestproblem2.not_started_yet!
    end
    
    context "if the user can participate" do
      before { sign_in_view(user) }
        
      it "renders the page correctly" do
        render template: "contests/index"
        should have_selector("table", class: "greyy")
        should have_link("Concours ##{contest.number}", href: contest_path(contest))
        should have_content("(à venir)")
        should have_content("Aucun problème corrigé")
      end
    end
    
    context "if the user cannot participate" do
      before { sign_in_view(user_bad) }
        
      it "renders the page correctly" do
        render template: "contests/index"
        should have_content("Les problèmes des concours sont accessibles par tous, mais il est nécessaire d'avoir au moins 200 points pour y participer.")
        should have_selector("table", class: "greyy")
        should have_link("Concours ##{contest.number}", href: contest_path(contest))
      end
    end
  end
  
  context "if the contest is in progress" do
    before do
      contest.in_progress!
      contestproblem1.corrected!
      contestproblem2.in_progress!
    end
    
    context "if the user can participate" do
      before { sign_in_view(user) }
        
      it "renders the page correctly" do
        render template: "contests/index"
        should have_selector("table", class: "orangey")
        should have_link("Concours ##{contest.number}", href: contest_path(contest))
        should have_content("(en cours)")
        should have_content("Après 1 problème :")
        should have_content("Personne n'a résolu de problème")
      end
    end
  end
  
  context "if the contest is finished" do
    let!(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user, score: 5, corrected: true) }
    let!(:contestsolution2) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user2, score: 3, corrected: true) }
    let!(:contestscore) { FactoryGirl.create(:contestscore, contest: contest, user: user, rank: 1, score: 5) }
    let!(:contestscore2) { FactoryGirl.create(:contestscore, contest: contest, user: user2, rank: 2, score: 3) }
    before do
      contest.completed!
      contest.update_attribute(:num_participants, 2)
      contestproblem1.corrected!
      contestproblem2.corrected!
    end
    
    context "if the user can participate" do
      before { sign_in_view(user) }
        
      it "renders the page correctly" do
        render template: "contests/index"
        should have_selector("table", class: "yellowy")
        should have_link("Concours ##{contest.number}", href: contest_path(contest))
        should have_content("(terminé)")
        should have_content("À la fin du concours :")
        should have_content("2 participants classés")
        should have_content("Meilleur score : 5/14 (1 fois)")
      end
    end
  end
end
