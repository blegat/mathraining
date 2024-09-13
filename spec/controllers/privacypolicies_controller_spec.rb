# -*- coding: utf-8 -*-
require "spec_helper"

describe PrivacypoliciesController, type: :controller, privacypolicy: true do

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:privacypolicy_online) { FactoryGirl.create(:privacypolicy, online: true) }
  let(:privacypolicy_offline) { FactoryGirl.create(:privacypolicy, online: false) }
  
  context "if the user is not a root" do
    before do
      sign_in_controller(admin)
    end
    
    it "renders the error page for index" do
      get :index
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for new" do
      get :new
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for edit" do
      get :edit, params: {id: privacypolicy_offline.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      patch :update, params: {id: privacypolicy_offline.id, privacypolicy: FactoryGirl.attributes_for(:privacypolicy)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: privacypolicy_offline.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for put_online" do
      put :put_online, params: {privacypolicy_id: privacypolicy_offline.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is a root" do
    before do
      sign_in_controller(root)
    end

    it "renders the error page for edit of an online privacypolicy" do
      get :edit, params: {id: privacypolicy_online.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy of an online privacypolicy" do
      delete :destroy, params: {id: privacypolicy_online.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for put_online of an online privacypolicy" do
      put :put_online, params: {privacypolicy_id: privacypolicy_online.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for show of an offline privacypolicy" do
      get :show, params: {id: privacypolicy_offline.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
