# -*- coding: utf-8 -*-
require "spec_helper"

describe "contests/_results.html.erb", type: :view, contest: true do

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
      before do
        assign(:signed_in, true)
        assign(:current_user, user_organizer)
      end
    
      it "renders no result" do
        render partial: "contests/results"
        expect(rendered).to have_content("Personne n'a résolu de problème")
        expect(rendered).to have_no_selector("table", id: "results-table")
      end
    end
  end
  
  context "if some contestproblems are corrected" do
    let!(:contestscore1) { FactoryGirl.create(:contestscore, contest: contest, user: user1, rank: 2, score: 7, medal: -1) }
    let!(:contestscore2) { FactoryGirl.create(:contestscore, contest: contest, user: user2, rank: 1, score: 11, medal: -1) }
      
    before do
      contest.in_correction!
      contestproblem1.corrected!
      contestproblem2.corrected!
      contestproblem3.in_correction!
    end
    
    context "and the user is not signed in" do
      before do
        assign(:signed_in, false)
      end
      
      it "does not render the results" do
        render partial: "contests/results"
        expect(rendered).to have_content("Le classement n'est visible que par les utilisateurs connectés")
        expect(rendered).to have_no_selector("table", id: "results-table")
      end
    end
    
    context "and the user is an organizer" do
      before do
        assign(:signed_in, true)
        assign(:current_user, user_organizer)
      end
    
      it "renders the results correctly" do
        render partial: "contests/results"
        expect(rendered).to have_selector("table", id: "results-table")
        
        expect(rendered).to have_selector("tr", id: "line-#{user1.id}")
        expect(rendered).to have_selector("td", id: "rank-#{user1.id}", text: "2.")
        expect(rendered).to have_no_selector("td", id: "medal-#{user1.id}")
        expect(rendered).to have_selector("td", id: "name-#{user1.id}", text: user1.name)
        expect(rendered).to have_selector("td", id: "score-#{user1.id}-#{contestproblem1.id}", text: "7", class: "contest-score-green")
        expect(rendered).to have_link("7", href: contestproblem_path(contestproblem1, :sol => contestsolution11))
        expect(rendered).to have_selector("td", id: "score-#{user1.id}-#{contestproblem2.id}", text: "0", class: "contest-score-red")
        expect(rendered).to have_link("0", href: contestproblem_path(contestproblem2, :sol => contestsolution21))
        expect(rendered).to have_no_selector("td", id: "score-#{user1.id}-#{contestproblem3.id}")
        expect(rendered).to have_selector("td", id: "total-score-#{user1.id}", text: "7")
        
        expect(rendered).to have_selector("tr", id: "line-#{user2.id}")
        expect(rendered).to have_selector("td", id: "rank-#{user2.id}", text: "1.")
        expect(rendered).to have_no_selector("td", id: "medal-#{user2.id}")
        expect(rendered).to have_selector("td", id: "name-#{user2.id}", text: user2.name)
        expect(rendered).to have_selector("td", id: "score-#{user2.id}-#{contestproblem1.id}", text: "4", class: "contest-score-orange")
        expect(rendered).to have_link("4", href: contestproblem_path(contestproblem1, :sol => contestsolution12))
        expect(rendered).to have_selector("td", id: "score-#{user2.id}-#{contestproblem2.id}", text: "", class: "contest-score-red")
        expect(rendered).to have_no_selector("td", id: "score-#{user2.id}-#{contestproblem3.id}")
        expect(rendered).to have_selector("td", id: "total-score-#{user2.id}", text: "11")
        
        expect(rendered).to have_no_selector("tr", id: "line-#{user3.id}")
      end
    end
    
    context "and the user is a participant" do
      before do
        assign(:signed_in, true)
        assign(:current_user, user1)
      end
    
      it "renders the results correctly" do
        render partial: "contests/results"
        expect(rendered).to have_selector("table", id: "results-table")
        
        expect(rendered).to have_selector("tr", id: "line-#{user1.id}")
        expect(rendered).to have_selector("td", id: "rank-#{user1.id}", text: "2.")
        expect(rendered).to have_no_selector("td", id: "medal-#{user1.id}")
        expect(rendered).to have_selector("td", id: "name-#{user1.id}", text: user1.name)
        expect(rendered).to have_selector("td", id: "score-#{user1.id}-#{contestproblem1.id}", text: "7", class: "contest-score-green")
        expect(rendered).to have_link("7", href: contestproblem_path(contestproblem1, :sol => contestsolution11))
        expect(rendered).to have_selector("td", id: "score-#{user1.id}-#{contestproblem2.id}", text: "", class: "contest-score-red") # 0 not visible for a participant
        expect(rendered).to have_no_link("0", href: contestproblem_path(contestproblem2, :sol => contestsolution21)) # idem
        expect(rendered).to have_no_selector("td", id: "score-#{user1.id}-#{contestproblem3.id}")
        expect(rendered).to have_selector("td", id: "total-score-#{user1.id}", text: "7")
        
        expect(rendered).to have_selector("tr", id: "line-#{user2.id}")
        expect(rendered).to have_selector("td", id: "rank-#{user2.id}", text: "1.")
        expect(rendered).to have_no_selector("td", id: "medal-#{user2.id}")
        expect(rendered).to have_selector("td", id: "name-#{user2.id}", text: user2.name)
        expect(rendered).to have_selector("td", id: "score-#{user2.id}-#{contestproblem1.id}", text: "4", class: "contest-score-orange")
        expect(rendered).to have_no_link("4", href: contestproblem_path(contestproblem1, :sol => contestsolution12)) # no link
        expect(rendered).to have_selector("td", id: "score-#{user2.id}-#{contestproblem2.id}", text: "", class: "contest-score-red")
        expect(rendered).to have_no_selector("td", id: "score-#{user2.id}-#{contestproblem3.id}")
        expect(rendered).to have_selector("td", id: "total-score-#{user2.id}", text: "11")
        
        expect(rendered).to have_no_selector("tr", id: "line-#{user3.id}")
      end
    end
  end
end
