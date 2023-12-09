# -*- coding: utf-8 -*-
require "spec_helper"

describe MessagesController, type: :controller, message: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:root) { FactoryGirl.create(:root) }
  let(:subject) { FactoryGirl.create(:subject) }
  let(:message) { FactoryGirl.create(:message, subject: subject) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end
    
    context "and the message is his message" do
      before do
        message.update_attribute(:user, user)
      end
    
      it "renders the error page for destroy" do
        delete :destroy, params: {id: message.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    context "and the message is not his message" do
      it "renders the error page for update" do
        patch :update, params: {id: message.id, message: FactoryGirl.attributes_for(:message)}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for destroy" do
        delete :destroy, params: {id: message.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
    
    context "and he cannot see the subject" do
      before do
        subject.update_attribute(:for_wepion, true)
      end
      
      it "renders the error page for create" do
        post :create, params: {subject_id: subject.id, message: FactoryGirl.attributes_for(:message)}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
  
  context "if the user is an admin" do
    before do
      sign_in_controller(admin)
    end
    
    context "and the message is from another admin" do
      before do
        message.user.update_attribute(:admin, true)
      end
      
      it "renders the error page for update" do
        patch :update, params: {id: message.id, message: FactoryGirl.attributes_for(:message)}
        expect(response).to render_template 'errors/access_refused'
      end
      
      it "renders the error page for destroy" do
        delete :destroy, params: {id: message.id}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
end
