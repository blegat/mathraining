# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestproblemsController, type: :controller, contestproblem: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_organizer) { FactoryGirl.create(:advanced_user) }
  let(:user) { FactoryGirl.create(:advanced_user) }
  let(:contest) { FactoryGirl.create(:contest) }
  let(:contestproblem) { FactoryGirl.create(:contestproblem, contest: contest) }
  
  before do
    contest.organizers << user_organizer
  end
  
  context "if the user is not connected" do
    context "and contestproblem is corrected" do
      before do
        contest.in_progress!
        contestproblem.corrected!
      end
      
      it "renders the sign in page for show" do
        get :show, params: {id: contestproblem.id}
        expect(response).to redirect_to signin_path
      end
    end
  end
  
  context "if the user is not an organizer" do
    before do
      sign_in_controller(user)
    end
    
    context "and contest is offline" do
      before do
        contest.in_construction!
        contestproblem.in_construction!
      end
      
      it "renders the error page for show" do
        get :show, params: {id: contestproblem.id}
        expect(response).to render_template 'errors/access_refused'
      end
    
      it "renders the error page for new" do
        get :new, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for create" do
        post :create, params: {contest_id: contest.id, contestproblem: FactoryGirl.attributes_for(:contestproblem)}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for edit" do
        get :edit, params: {id: contestproblem.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for update" do
        post :update, params: {id: contestproblem.id, contestproblem: FactoryGirl.attributes_for(:contestproblem)}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for destroy" do
        delete :destroy, params: {id: contestproblem.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    context "and contest is online but not problem" do
      before do
        contest.in_progress!
        contestproblem.not_started_yet!
      end
      
      it "renders the error page for show" do
        get :show, params: {id: contestproblem.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
  
  context "if the user is an organizer" do
    before do
      sign_in_controller(user_organizer)
    end
    
    context "and contest is online" do
      before do
        contest.in_progress!
        contestproblem.not_started_yet!
      end
      
      it "renders the error page for new" do
        get :new, params: {contest_id: contest.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for create" do
        post :create, params: {contest_id: contest.id, contestproblem: FactoryGirl.attributes_for(:contestproblem)}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for destroy" do
        delete :destroy, params: {id: contestproblem.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    context "and contest problem is corrected" do
      before do
        contest.in_progress!
        contestproblem.corrected!
      end
      
      it "renders the error page for authorize_corrections" do
        put :authorize_corrections, params: {contestproblem_id: contestproblem.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for unauthorize_corrections" do
        put :unauthorize_corrections, params: {contestproblem_id: contestproblem.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
end
