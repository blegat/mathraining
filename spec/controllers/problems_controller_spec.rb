# -*- coding: utf-8 -*-
require "spec_helper"

describe ProblemsController, type: :controller, problem: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user, rating: 200) }
  let(:section) { FactoryGirl.create(:section) }
  let(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let(:online_problem) { FactoryGirl.create(:problem, online: true) }
  let(:offline_problem) { FactoryGirl.create(:problem, online: false) }
  
  before { online_problem.chapters << chapter }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for show of offline problem" do
      get :show, params: {id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for show of online problem that he can't see" do
      get :show, params: {id: online_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for new" do
      get :new, params: {section_id: section.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {section_id: section.id, problem: FactoryGirl.attributes_for(:problem)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for edit" do
      get :edit, params: {id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: offline_problem.id, chapter: FactoryGirl.attributes_for(:problem)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for order" do
      put :order, params: {problem_id: offline_problem.id, new_position: 3}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for put_online" do
      put :put_online, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for edit_explanation" do
      get :edit_explanation, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update_explanation" do
      patch :update_explanation, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for edit_markscheme" do
      get :edit_markscheme, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update_markscheme" do
      patch :update_markscheme, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for add_prerequisite" do
      post :add_prerequisite, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for delete_prerequisite" do
      put :delete_prerequisite, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for add_virtualtest" do
      post :add_virtualtest, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for manage_externalsolutions" do
      get :manage_externalsolutions, params: {problem_id: offline_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is an admin" do
    before do
      sign_in_controller(admin)
    end
    
    it "renders the error page for destroy of online problem" do
      delete :destroy, params: {id: online_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for put_online of online problem" do
      put :put_online, params: {problem_id: online_problem.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
