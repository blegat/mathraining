# -*- coding: utf-8 -*-
require "spec_helper"

describe ExtractsController, type: :controller, extract: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:externalsolution) { FactoryGirl.create(:externalsolution) }
  let(:extract) { FactoryGirl.create(:extract) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for create" do
      post :create, params: {externalsolution_id: externalsolution.id, extract: FactoryGirl.attributes_for(:extract)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      patch :update, params: {id: extract.id, extract: FactoryGirl.attributes_for(:extract)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: extract.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
