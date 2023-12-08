# -*- coding: utf-8 -*-
require "spec_helper"

describe ItemsController, type: :controller, item: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:question) { FactoryGirl.create(:qcm, online: false) }
  let(:item) { FactoryGirl.create(:item, question: question) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    it "renders the error page for create" do
      post :create, params: {question_id: question.id, item: FactoryGirl.attributes_for(:item)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for update" do
      post :update, params: {id: item.id, faq: FactoryGirl.attributes_for(:item)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: item.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for correct" do
      put :correct, params: {item_id: item.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for uncorrect" do
      put :uncorrect, params: {item_id: item.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for order" do
      put :order, params: {item_id: item.id, new_position: 3}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is an admin" do
    before do
      sign_in_controller(admin)
    end
    
    context "and the question is online" do
      before do
        question.update_attribute(:online, true)
      end
      
      it "renders the error page for create" do
        post :create, params: {question_id: question.id, item: FactoryGirl.attributes_for(:item)}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for destroy" do
        delete :destroy, params: {id: item.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for correct" do
        put :correct, params: {item_id: item.id}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for uncorrect" do
        put :uncorrect, params: {item_id: item.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
end
