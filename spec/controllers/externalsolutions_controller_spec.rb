# -*- coding: utf-8 -*-
require "spec_helper"

describe ExternalsolutionsController, type: :controller, externalsolution: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:problem) { FactoryGirl.create(:problem) }
  let(:externalsolution) { FactoryGirl.create(:externalsolution) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for create" do
      post :create, params: {problem_id: problem.id, externalsolution: FactoryGirl.attributes_for(:externalsolution)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      patch :update, params: {id: externalsolution.id, externalsolution: FactoryGirl.attributes_for(:externalsolution)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: externalsolution.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
