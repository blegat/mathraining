# -*- coding: utf-8 -*-
require "spec_helper"

describe ActualitiesController, type: :controller, actuality: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:actuality) { FactoryGirl.create(:actuality) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for new" do
      get :new
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {actuality: FactoryGirl.attributes_for(:actuality)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for edit" do
      get :edit, params: {id: actuality.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: actuality.id, actuality: FactoryGirl.attributes_for(:actuality)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: actuality.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
