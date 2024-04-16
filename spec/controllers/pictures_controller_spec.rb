# -*- coding: utf-8 -*-
require "spec_helper"

describe PicturesController, type: :controller, picture: true do

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:picture) { FactoryGirl.create(:picture, user: root) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for show" do
      get :show, params: {id: picture.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for index" do
      get :index
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for new" do
      get :new
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {picture: FactoryGirl.attributes_for(:picture)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: picture.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is not a root (and not the author)" do
    before do
      sign_in_controller(admin)
    end
    
    it "renders the error page for show" do
      get :show, params: {id: picture.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: picture.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is a visitor" do
    it "renders the error page for image without key" do
      get :image, params: {picture_id: picture.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for image with wrong key" do
      get :image, params: {picture_id: picture.id, key: picture.access_key + "WRONG"}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "does not render the error page for image with correct key" do
      get :image, params: {picture_id: picture.id, key: picture.access_key}
      expect(response).not_to render_template 'errors/access_refused'
    end
  end
end
