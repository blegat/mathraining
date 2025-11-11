# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestcorrections/_show.html.erb", type: :view, contestcorrection: true do

  subject { rendered }

  let(:user) { FactoryBot.create(:user) }
  let!(:contestproblem) { FactoryBot.create(:contestproblem, status: :corrected) }
  let!(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, official: false, score: 4) }
  let!(:contestsolution_official) { contestproblem.contestsolutions.where(:official => true).first }
  
  before do
    contestproblem.contest.organizers << user
    assign(:contestproblem, contestproblem)
    assign(:contest, contestproblem.contest)
    sign_in_view(user)
  end
  
  context "if the solution is official" do
    it "renders the solution, not the score, but the form" do
      render partial: "contestcorrections/show", locals: {contestsolution: contestsolution_official, contestcorrection: contestsolution_official.contestcorrection}
      should have_no_selector("h4", text: "Score obtenu")
      should have_no_content("/ 7")
      expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution_official.contestcorrection, kind: "contestcorrection", can_edit: true})
      expect(response).to render_template(:partial => "contestcorrections/_edit")
    end
  end
  
  context "if the solution is not official" do
    context "if the contestproblem is already corrected" do
      it "renders the solution and the score, but not the form" do
        render partial: "contestcorrections/show", locals: {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection}
        should have_selector("h4", text: "Score obtenu")
        should have_content("#{contestsolution.score} / 7")
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution.contestcorrection, kind: "contestcorrection", can_edit: false})
        expect(response).not_to render_template(:partial => "contestcorrections/_edit")
      end
    end
    
    context "if the contestproblem is in correction" do
      before { contestproblem.in_correction! }
      
      it "renders the solution, the score and the form" do
        render partial: "contestcorrections/show", locals: {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection}
        should have_selector("h4", text: "Score obtenu")
        should have_content("#{contestsolution.score} / 7")
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution.contestcorrection, kind: "contestcorrection", can_edit: true})
        expect(response).to render_template(:partial => "contestcorrections/_edit")
      end
    end
  end
end
