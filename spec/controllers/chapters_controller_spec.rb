# -*- coding: utf-8 -*-
require "spec_helper"

describe ChaptersController, type: :controller, chapter: true do

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  let(:online_chapter) { FactoryGirl.create(:chapter, online: true) }
  let(:offline_chapter) { FactoryGirl.create(:chapter, online: false) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for show of offline chapter" do
      get :show, params: {id: offline_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for new" do
      get :new, params: {section_id: section.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {section_id: section.id, chapter: FactoryGirl.attributes_for(:chapter)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for edit" do
      get :edit, params: {id: online_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: offline_chapter.id, chapter: FactoryGirl.attributes_for(:chapter)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: offline_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for order" do
      put :order, params: {chapter_id: offline_chapter.id, new_position: 3}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for read of offline chapter" do
      put :read, params: {chapter_id: offline_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is an admin (not a root)" do
    before do
      sign_in_controller(admin)
    end
    
    it "renders the error page for put_online" do
      put :put_online, params: {chapter_id: offline_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for mark_submission_prerequisite" do
      put :mark_submission_prerequisite, params: {chapter_id: offline_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for unmark_submission_prerequisite" do
      put :unmark_submission_prerequisite, params: {chapter_id: offline_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for read" do
      put :read, params: {chapter_id: online_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is a root" do
    before do
      sign_in_controller(root)
    end
    
    it "renders the error page for put_online of online chapter" do
      put :put_online, params: {chapter_id: online_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy of online chapter" do
      delete :destroy, params: {id: online_chapter.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
