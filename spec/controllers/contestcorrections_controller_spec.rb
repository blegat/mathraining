# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestcorrectionsController, type: :controller, contestcorrection: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:contestproblem) { FactoryGirl.create(:contestproblem) }
  let(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false) }
  let(:contestcorrection) { contestsolution.contestcorrection }
  
  before do
    contestproblem.contest.organizers << user
  end
  
  context "if the user is not an organizer" do
    before do
      sign_in_controller(admin)
      contestproblem.in_correction!
    end
    
    it "renders the error page for update" do
      post :update, params: {id: contestcorrection.id, contestcorrection: FactoryGirl.attributes_for(:contestcorrection)}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end


