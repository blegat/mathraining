# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestsController, type: :controller, contest: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_organizer) { FactoryGirl.create(:advanced_user) }
  let(:user) { FactoryGirl.create(:advanced_user) }
  let(:contest) { FactoryGirl.create(:contest) }
  
  before do
    contest.organizers << user_organizer
  end
  
  context "if the user is not an organizer" do
    before do
      sign_in_controller(user)
    end
    
    context "and contest is offline" do
      before do
        contest.in_construction!
      end
      
      it "renders the error page for show" do
        get :show, params: {id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    it "renders the error page for edit" do
      get :edit, params: {id: contest.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: contest.id, contest: FactoryGirl.attributes_for(:contest)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    context "and cutoffs can be defined by organizers" do
      before do
        contest.update_attribute(:medal, true)
        contest.completed!
      end
      
      it "renders the error page for cutoffs" do
        get :cutoffs, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for define_cutoffs" do
        post :define_cutoffs, params: {contest_id: contest.id, bronze_cutoff: 1, silver_cutoff: 2, gold_cutoff: 3}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
  
  context "if the user is an organizer" do
    before do
      sign_in_controller(user_organizer)
    end
    
    it "renders the error page for new" do
      get :new
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for create" do
      post :create, params: {contest: FactoryGirl.attributes_for(:contest)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: contest.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    context "and contest is offline" do
      before do
        contest.in_construction!
      end
      
      it "renders the error page for put_online" do
        put :put_online, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    context "and medals are already distributed" do
      before do
        contest.update(medal: true, bronze_cutoff: 1, silver_cutoff: 2, gold_cutoff: 3)
        contest.completed!
      end
      
      it "renders the error page for cutoffs" do
        get :cutoffs, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for define_cutoffs" do
        post :define_cutoffs, params: {contest_id: contest.id, bronze_cutoff: 2, silver_cutoff: 3, gold_cutoff: 4}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    context "and no medals can be given" do
      before do
        contest.update(medal: false, bronze_cutoff: 0, silver_cutoff: 0, gold_cutoff: 0)
        contest.completed!
      end
      
      it "renders the error page for cutoffs" do
        get :cutoffs, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for define_cutoffs" do
        post :define_cutoffs, params: {contest_id: contest.id, bronze_cutoff: 2, silver_cutoff: 3, gold_cutoff: 4}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    context "and contest is not completed" do
      before do
        contest.update(medal: true, bronze_cutoff: 0, silver_cutoff: 0, gold_cutoff: 0)
        contest.in_correction!
      end
      
      it "renders the error page for cutoffs" do
        get :cutoffs, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for define_cutoffs" do
        post :define_cutoffs, params: {contest_id: contest.id, bronze_cutoff: 2, silver_cutoff: 3, gold_cutoff: 4}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
  
  context "if the user is an admin" do
    before do
      sign_in_controller(admin)
    end
    
    context "and contest is online" do
      before do
        contest.in_progress!
      end
      
      it "renders the error page for destroy" do
        delete :destroy, params: {id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for put_online" do
        put :put_online, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
end
