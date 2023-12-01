# -*- coding: utf-8 -*-
require "spec_helper"

describe CategoriesController, type: :controller, category: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:category) { FactoryGirl.create(:category) }
  
  context "if the user is not a root" do
    before do
      sign_in_controller(admin)
    end
    
    it "renders the error page for index" do
      get :index
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {category: FactoryGirl.attributes_for(:category)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: category.id, category: FactoryGirl.attributes_for(:category)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: category.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
