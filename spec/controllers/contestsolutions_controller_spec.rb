# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestsolutionsController, type: :controller, contestsolution: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user_other) { FactoryGirl.create(:user) }
  let(:contestproblem) { FactoryGirl.create(:contestproblem) }
  let(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false) }
  
  before do
    contestproblem.contest.organizers << user
  end
  
  context "if the user is not signed in" do
    it "renders the error page for create" do
      post :create, params: {contestproblem_id: contestproblem.id, contestsolution: FactoryGirl.attributes_for(:contestsolution)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      patch :update, params: {id: contestsolution.id, contestsolution: FactoryGirl.attributes_for(:contestsolution)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: contestsolution.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is an admin, not organizer" do
    before do
      sign_in_controller(admin)
      contestproblem.in_correction!
    end
    
    it "renders the error page for reserve" do
      put :reserve, params: {contestsolution_id: contestsolution.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for unreserve" do
      put :unreserve, params: {contestsolution_id: contestsolution.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is a participant with a solution" do
    let!(:contestsolution_other) { FactoryGirl.create(:contestsolution, user: user_other, contestproblem: contestproblem, official: false) }
   
    before do
      sign_in_controller(user_other)
      contestproblem.in_progress!
    end
    
    it "renders the error page when trying to update the solution of someone else" do
      patch :update, params: {id: contestsolution.id, contestsolution: FactoryGirl.attributes_for(:contestsolution)}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end


