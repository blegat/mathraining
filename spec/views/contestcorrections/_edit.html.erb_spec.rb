# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestcorrections/_edit.html.erb", type: :view, contestcorrection: true do

  subject { rendered }

  let(:user) { FactoryBot.create(:user) }
  let(:contestproblem) { FactoryBot.create(:contestproblem) }
  let(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, official: false) }
  let(:contestsolution_official) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, official: true) }
  
  before do
    contestproblem.contest.organizers << user
    assign(:contestproblem, contestproblem)
    assign(:contest, contestproblem.contest)
    sign_in_view(user)
  end
  
  context "if the solution is official" do      
    it "renders the correct fields and buttons" do
      render partial: "contestcorrections/edit", locals: {contestsolution: contestsolution_official, contestcorrection: contestsolution_official.contestcorrection, can_edit_correction: true}
      should have_field("MathInput")
      should have_no_field("score")
      should have_button("Enregistrer (non-publique)")
      should have_button("Enregistrer (publique)")
      should have_button("Enregistrer (publique étoilée)")
      should have_button("Annuler")
    end
  end
  
  context "if the solution is not official" do
    it "renders the correct fields and buttons" do
      render partial: "contestcorrections/edit", locals: {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection, can_edit_correction: true}
      should have_field("MathInput")
      should have_field("score")
      should have_button("Enregistrer provisoirement")
      should have_button("Enregistrer")
      should have_button("Enregistrer et étoiler")
      should have_button("Annuler")
    end
  end
end
