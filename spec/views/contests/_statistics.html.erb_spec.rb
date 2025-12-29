# -*- coding: utf-8 -*-
require "spec_helper"

describe "contests/_statistics.html.erb", type: :view, contest: true do

  subject { rendered }

  let!(:user1) { FactoryBot.create(:advanced_user) }
  let!(:user2) { FactoryBot.create(:advanced_user) }
  let!(:user3) { FactoryBot.create(:advanced_user) }
  let!(:contest) { FactoryBot.create(:contest, status: :completed) }
  let!(:contestproblem1) { FactoryBot.create(:contestproblem, contest: contest, number: 1, status: :corrected) }
  let!(:contestproblem2) { FactoryBot.create(:contestproblem, contest: contest, number: 2, status: :corrected) }
  let!(:contestproblem3) { FactoryBot.create(:contestproblem, contest: contest, number: 3, status: :in_correction) }
  let!(:contestproblem4) { FactoryBot.create(:contestproblem, contest: contest, number: 3, status: :not_started_yet) }
  let!(:contestsolution11) { FactoryBot.create(:contestsolution, contestproblem: contestproblem1, user: user1, corrected: true, score: 7) }
  let!(:contestsolution12) { FactoryBot.create(:contestsolution, contestproblem: contestproblem1, user: user2, corrected: true, score: 4) }
  let!(:contestsolution13) { FactoryBot.create(:contestsolution, contestproblem: contestproblem1, user: user3, corrected: true, score: 0) }
  let!(:contestsolution21) { FactoryBot.create(:contestsolution, contestproblem: contestproblem2, user: user1, corrected: true, score: 0) }
  let!(:contestsolution31) { FactoryBot.create(:contestsolution, contestproblem: contestproblem3, user: user2, corrected: true, score: 3) }
  let!(:contestscore1) { FactoryBot.create(:contestscore, contest: contest, user: user1, rank: 1, score: 7) }
  let!(:contestscore2) { FactoryBot.create(:contestscore, contest: contest, user: user2, rank: 2, score: 4) }
  
  before { assign(:contest, contest) }
    
  context "and the user is connected" do
    before { sign_in_view(user1) }
  
    it "renders the statistics correctly" do
      render partial: "contests/statistics"
      
      should have_link("Problème ##{contestproblem1.number}", href: contestproblem_path(contestproblem1))
      should have_selector("td", id: "num-0-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-1-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-2-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-3-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-4-#{contestproblem1.id}", text: "1")
      should have_selector("td", id: "num-5-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-6-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-7-#{contestproblem1.id}", text: "1")
      should have_selector("td", id: "average-#{contestproblem1.id}", text: "5.50")
      
      should have_link("Problème ##{contestproblem2.number}", href: contestproblem_path(contestproblem2))
      should have_selector("td", id: "num-0-#{contestproblem2.id}", text: "2")
      should have_selector("td", id: "num-1-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-2-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-3-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-4-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-5-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-6-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-7-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "average-#{contestproblem2.id}", text: "0.00")
      
      should have_link("Problème ##{contestproblem3.number}", href: contestproblem_path(contestproblem3))
      should have_selector("td", id: "num-0-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-1-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-2-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-3-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-4-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-5-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-6-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-7-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "average-#{contestproblem3.id}", text: "")
      
      should have_no_link("Problème ##{contestproblem4.number}", href: contestproblem_path(contestproblem4)) # Because not started yet
      should have_selector("td", id: "num-0-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-1-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-2-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-3-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-4-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-5-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-6-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-7-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "average-#{contestproblem4.id}", text: "")
    end
  end
  
  context "and the user is not connected" do
    it "renders the statistics correctly but without links to problems" do
      render partial: "contests/statistics"
      
      should have_no_link("Problème ##{contestproblem1.number}", href: contestproblem_path(contestproblem1))
      should have_content("Problème ##{contestproblem1.number}")
      should have_selector("td", id: "num-0-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-1-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-2-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-3-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-4-#{contestproblem1.id}", text: "1")
      should have_selector("td", id: "num-5-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-6-#{contestproblem1.id}", text: "-")
      should have_selector("td", id: "num-7-#{contestproblem1.id}", text: "1")
      should have_selector("td", id: "average-#{contestproblem1.id}", text: "5.50")
      
      should have_no_link("Problème ##{contestproblem2.number}", href: contestproblem_path(contestproblem2))
      should have_content("Problème ##{contestproblem2.number}")
      should have_selector("td", id: "num-0-#{contestproblem2.id}", text: "2")
      should have_selector("td", id: "num-1-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-2-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-3-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-4-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-5-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-6-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "num-7-#{contestproblem2.id}", text: "-")
      should have_selector("td", id: "average-#{contestproblem2.id}", text: "0.00")
      
      should have_no_link("Problème ##{contestproblem3.number}", href: contestproblem_path(contestproblem3))
      should have_selector("td", id: "num-0-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-1-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-2-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-3-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-4-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-5-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-6-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "num-7-#{contestproblem3.id}", text: "")
      should have_selector("td", id: "average-#{contestproblem3.id}", text: "")
      
      should have_no_link("Problème ##{contestproblem4.number}", href: contestproblem_path(contestproblem4))
      should have_selector("td", id: "num-0-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-1-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-2-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-3-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-4-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-5-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-6-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "num-7-#{contestproblem4.id}", text: "")
      should have_selector("td", id: "average-#{contestproblem4.id}", text: "")
    end
  end
end
