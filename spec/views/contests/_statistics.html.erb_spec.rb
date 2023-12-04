# -*- coding: utf-8 -*-
require "spec_helper"

describe "contests/_statistics.html.erb", type: :view, contest: true do

  let!(:user1) { FactoryGirl.create(:advanced_user) }
  let!(:user2) { FactoryGirl.create(:advanced_user) }
  let!(:user3) { FactoryGirl.create(:advanced_user) }
  let!(:contest) { FactoryGirl.create(:contest, status: :completed) }
  let!(:contestproblem1) { FactoryGirl.create(:contestproblem, contest: contest, number: 1, status: :corrected) }
  let!(:contestproblem2) { FactoryGirl.create(:contestproblem, contest: contest, number: 2, status: :corrected) }
  let!(:contestsolution11) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user1, corrected: true, score: 7) }
  let!(:contestsolution12) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user2, corrected: true, score: 4) }
  let!(:contestsolution13) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user3, corrected: true, score: 0) }
  let!(:contestsolution21) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem2, user: user1, corrected: true, score: 0) }
  let!(:contestscore1) { FactoryGirl.create(:contestscore, contest: contest, user: user1, rank: 1, score: 7) }
  let!(:contestscore2) { FactoryGirl.create(:contestscore, contest: contest, user: user2, rank: 2, score: 4) }
  
  before do
    assign(:contest, contest)
  end
    
  context "and the user is connected" do
    before do
      assign(:signed_in, true)
      assign(:current_user, user1)
    end
  
    it "renders the statistics correctly" do
      render partial: "contests/statistics"
      
      expect(rendered).to have_link("Problème ##{contestproblem1.number}", href: contestproblem_path(contestproblem1))
      expect(rendered).to have_selector("td", id: "num-0-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-1-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-2-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-3-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-4-#{contestproblem1.id}", text: "1")
      expect(rendered).to have_selector("td", id: "num-5-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-6-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-7-#{contestproblem1.id}", text: "1")
      expect(rendered).to have_selector("td", id: "average-#{contestproblem1.id}", text: "5.50")
      
      expect(rendered).to have_link("Problème ##{contestproblem2.number}", href: contestproblem_path(contestproblem2))
      expect(rendered).to have_selector("td", id: "num-0-#{contestproblem2.id}", text: "2")
      expect(rendered).to have_selector("td", id: "num-1-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-2-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-3-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-4-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-5-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-6-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-7-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "average-#{contestproblem2.id}", text: "0.00")
    end
  end
  
  context "and the user is not connected" do
    it "renders the statistics correctly but without links to problems" do
      render partial: "contests/statistics"
      
      expect(rendered).to have_no_link("Problème ##{contestproblem1.number}", href: contestproblem_path(contestproblem1))
      expect(rendered).to have_content("Problème ##{contestproblem1.number}")
      expect(rendered).to have_selector("td", id: "num-0-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-1-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-2-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-3-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-4-#{contestproblem1.id}", text: "1")
      expect(rendered).to have_selector("td", id: "num-5-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-6-#{contestproblem1.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-7-#{contestproblem1.id}", text: "1")
      expect(rendered).to have_selector("td", id: "average-#{contestproblem1.id}", text: "5.50")
      
      expect(rendered).to have_no_link("Problème ##{contestproblem2.number}", href: contestproblem_path(contestproblem2))
      expect(rendered).to have_content("Problème ##{contestproblem2.number}")
      expect(rendered).to have_selector("td", id: "num-0-#{contestproblem2.id}", text: "2")
      expect(rendered).to have_selector("td", id: "num-1-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-2-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-3-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-4-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-5-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-6-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "num-7-#{contestproblem2.id}", text: "-")
      expect(rendered).to have_selector("td", id: "average-#{contestproblem2.id}", text: "0.00")
    end
  end
end
