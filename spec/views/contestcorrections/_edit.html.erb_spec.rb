# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestcorrections/_edit.html.erb", type: :view, contestcorrection: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:contestproblem) { FactoryGirl.create(:contestproblem) }
  let(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false) }
  let(:contestsolution_official) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: true) }
  
  before do
    contestproblem.contest.organizers << user
    assign(:contestproblem, contestproblem)
    assign(:contest, contestproblem.contest)
    assign(:signed_in, true)
    assign(:current_user, user)
  end
  
  context "if the solution is official" do      
    it "renders the correct fields and buttons" do
      render partial: "contestcorrections/edit", locals: {contestsolution: contestsolution_official, contestcorrection: contestsolution_official.contestcorrection, can_edit_correction: true}
      expect(rendered).to have_field("MathInput")
      expect(rendered).to have_no_field("score")
      expect(rendered).to have_button("Enregistrer (non-publique)")
      expect(rendered).to have_button("Enregistrer (publique)")
      expect(rendered).to have_button("Enregistrer (publique étoilée)")
      expect(rendered).to have_button("Annuler")
    end
  end
  
  context "if the solution is not official" do
    it "renders the correct fields and buttons" do
      render partial: "contestcorrections/edit", locals: {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection, can_edit_correction: true}
      expect(rendered).to have_field("MathInput")
      expect(rendered).to have_field("score")
      expect(rendered).to have_button("Enregistrer provisoirement")
      expect(rendered).to have_button("Enregistrer")
      expect(rendered).to have_button("Enregistrer et étoiler")
      expect(rendered).to have_button("Annuler")
    end
  end
end
