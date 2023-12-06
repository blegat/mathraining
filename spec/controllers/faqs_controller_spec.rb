# -*- coding: utf-8 -*-
require "spec_helper"

describe FaqsController, type: :controller, faq: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:faq) { FactoryGirl.create(:faq) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for new" do
      get :new
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {faq: FactoryGirl.attributes_for(:faq)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for edit" do
      get :edit, params: {id: faq.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: faq.id, faq: FactoryGirl.attributes_for(:faq)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: faq.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for order" do
      put :order, params: {faq_id: faq.id, new_position: 3}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
