# -*- coding: utf-8 -*-
require "spec_helper"

describe PrerequisitesController, type: :controller, prerequisite: true do

  let(:user) { FactoryGirl.create(:user) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for graph_prerequisites" do
      get :graph_prerequisites
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for add_prerequisite" do
      post :add_prerequisite, params: {prerequisite: FactoryGirl.attributes_for(:prerequisite)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for remove_prerequisite" do
      post :remove_prerequisite, params: {prerequisite: FactoryGirl.attributes_for(:prerequisite)}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
