# -*- coding: utf-8 -*-
require "spec_helper"

describe CorrectionsController, type: :controller, correction: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:submission) { FactoryGirl.create(:submission, user: user) }
  
  context "if the user is not involved in submission" do
    before do
      sign_in_controller(other_user)
    end
    
    it "renders the error page for create" do
      post :create, params: {submission_id: submission.id, correction: FactoryGirl.attributes_for(:correction)}
      expect(response).to render_template 'errors/access_refused'
    end
  end
  
  context "if the user is an admin" do
    before do
      sign_in_controller(admin)
    end
    
    context "but the submission is a draft" do
      before do
        submission.draft!
        submission.update_attribute(:visible, false)
      end
      
      it "renders the error page for create" do
        post :create, params: {submission_id: submission.id, correction: FactoryGirl.attributes_for(:correction)}
        expect(response).to render_template 'errors/access_refused'
      end
    end
  end
end
