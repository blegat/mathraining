# -*- coding: utf-8 -*-
require "spec_helper"

describe ColorsController, type: :controller, color: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:color) { FactoryGirl.create(:color) }
  
  context "if the user is not a root" do
    before do
      sign_in_controller(admin)
    end
    
    it "renders the error page for index" do
      get :index
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {color: FactoryGirl.attributes_for(:color)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: color.id, color: FactoryGirl.attributes_for(:color)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: color.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
