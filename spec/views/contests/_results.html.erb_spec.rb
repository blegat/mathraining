# -*- coding: utf-8 -*-
require "spec_helper"

describe "contests/_results.html.erb", type: :view, contest: true do

  subject { rendered }

  let!(:user1) { FactoryGirl.create(:advanced_user) }
  let!(:user2) { FactoryGirl.create(:advanced_user) }
  let!(:user3) { FactoryGirl.create(:advanced_user) }
  let!(:user_organizer) { FactoryGirl.create(:user) }
  let!(:contest) { FactoryGirl.create(:contest) }
  let!(:contestproblem1) { FactoryGirl.create(:contestproblem, contest: contest, number: 1) }
  let!(:contestproblem2) { FactoryGirl.create(:contestproblem, contest: contest, number: 2) }
  let!(:contestproblem3) { FactoryGirl.create(:contestproblem, contest: contest, number: 3) }
  let!(:contestsolution11) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user1, corrected: true, score: 7) }
  let!(:contestsolution12) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user2, corrected: true, score: 4) }
  let!(:contestsolution13) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user3, corrected: true, score: 0) }
  let!(:contestsolution21) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem2, user: user1, corrected: true, score: 0) }
  let!(:contestsolution31) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem3, user: user1, corrected: true, score: 7, star: true) }
  let!(:contestsolution32) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem3, user: user2, corrected: true, score: -1) }
  
  before do
    contest.organizers << user_organizer
    assign(:contest, contest)
  end
  
  context "if no contestproblem is corrected" do
    before do
      contest.in_correction!
      contestproblem1.in_correction!
      contestproblem2.in_correction!
      contestproblem3.in_correction!
    end
    
    context "and the user is an organizer" do
      before { sign_in_view(user_organizer) }
    
      it "renders no result" do
        render partial: "contests/results"
        should have_content("Personne n'a résolu de problème")
        should have_no_selector("table", id: "results-table")
      end
    end
  end
  
  context "if some contestproblems are corrected" do
    let!(:contestscore1) { FactoryGirl.create(:contestscore, contest: contest, user: user1, rank: 2, score: 7) }
    let!(:contestscore2) { FactoryGirl.create(:contestscore, contest: contest, user: user2, rank: 1, score: 11) }
      
    before do
      contest.in_correction!
      contestproblem1.corrected!
      contestproblem2.corrected!
      contestproblem3.in_correction!
    end
    
    context "and the user is not signed in" do      
      it "does not render the results" do
        render partial: "contests/results"
        should have_content("Le classement n'est visible que par les utilisateurs connectés")
        should have_no_selector("table", id: "results-table")
      end
    end
    
    context "and the user is an organizer" do
      before { sign_in_view(user_organizer) }
    
      it "renders the results correctly" do
        render partial: "contests/results"
        should have_selector("table", id: "results-table")
        
        should have_selector("tr", id: "line-#{user1.id}")
        should have_selector("td", id: "rank-#{user1.id}", text: "2.")
        should have_no_selector("td", id: "medal-#{user1.id}")
        should have_selector("td", id: "name-#{user1.id}", text: user1.name)
        should have_selector("td", id: "score-#{user1.id}-#{contestproblem1.id}", text: "7", class: "contest-score-green")
        should have_link("7", href: contestproblem_path(contestproblem1, :sol => contestsolution11))
        should have_selector("td", id: "score-#{user1.id}-#{contestproblem2.id}", text: "0", class: "contest-score-red")
        should have_link("0", href: contestproblem_path(contestproblem2, :sol => contestsolution21))
        should have_no_selector("td", id: "score-#{user1.id}-#{contestproblem3.id}")
        should have_selector("td", id: "total-score-#{user1.id}", text: "7")
        
        should have_selector("tr", id: "line-#{user2.id}")
        should have_selector("td", id: "rank-#{user2.id}", text: "1.")
        should have_no_selector("td", id: "medal-#{user2.id}")
        should have_selector("td", id: "name-#{user2.id}", text: user2.name)
        should have_selector("td", id: "score-#{user2.id}-#{contestproblem1.id}", text: "4", class: "contest-score-orange")
        should have_link("4", href: contestproblem_path(contestproblem1, :sol => contestsolution12))
        should have_selector("td", id: "score-#{user2.id}-#{contestproblem2.id}", text: "", class: "contest-score-red")
        should have_no_selector("td", id: "score-#{user2.id}-#{contestproblem3.id}")
        should have_selector("td", id: "total-score-#{user2.id}", text: "11")
        
        should have_no_selector("tr", id: "line-#{user3.id}")
      end
    end
    
    context "and the user is a participant" do
      before { sign_in_view(user1) }
    
      it "renders the results correctly" do
        render partial: "contests/results"
        should have_selector("table", id: "results-table")
        
        should have_selector("tr", id: "line-#{user1.id}")
        should have_selector("td", id: "rank-#{user1.id}", text: "2.")
        should have_no_selector("td", id: "medal-#{user1.id}")
        should have_selector("td", id: "name-#{user1.id}", text: user1.name)
        should have_selector("td", id: "score-#{user1.id}-#{contestproblem1.id}", text: "7", class: "contest-score-green")
        should have_link("7", href: contestproblem_path(contestproblem1, :sol => contestsolution11))
        should have_selector("td", id: "score-#{user1.id}-#{contestproblem2.id}", text: "", class: "contest-score-red") # 0 not visible for a participant
        should have_no_link("0", href: contestproblem_path(contestproblem2, :sol => contestsolution21)) # idem
        should have_no_selector("td", id: "score-#{user1.id}-#{contestproblem3.id}")
        should have_selector("td", id: "total-score-#{user1.id}", text: "7")
        
        should have_selector("tr", id: "line-#{user2.id}")
        should have_selector("td", id: "rank-#{user2.id}", text: "1.")
        should have_no_selector("td", id: "medal-#{user2.id}")
        should have_selector("td", id: "name-#{user2.id}", text: user2.name)
        should have_selector("td", id: "score-#{user2.id}-#{contestproblem1.id}", text: "4", class: "contest-score-orange")
        should have_no_link("4", href: contestproblem_path(contestproblem1, :sol => contestsolution12)) # no link
        should have_selector("td", id: "score-#{user2.id}-#{contestproblem2.id}", text: "", class: "contest-score-red")
        should have_no_selector("td", id: "score-#{user2.id}-#{contestproblem3.id}")
        should have_selector("td", id: "total-score-#{user2.id}", text: "11")
        
        should have_no_selector("tr", id: "line-#{user3.id}")
      end
    end
  end
end
