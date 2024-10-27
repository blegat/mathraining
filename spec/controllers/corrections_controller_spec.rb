# -*- coding: utf-8 -*-
require "spec_helper"

describe CorrectionsController, type: :controller, correction: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:submission) { FactoryGirl.create(:submission, user: user) }
  
  context "if the user is not involved in submission" do
    before { sign_in_controller(other_user) }
    
    it { expect(response).to have_controller_create_behavior('correction', :access_refused, {:submission_id => submission.id}) }
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    context "but the submission is a draft" do
      before do
        submission.draft!
        submission.update_attribute(:visible, false)
      end
      
      it { expect(response).to have_controller_create_behavior('correction', :access_refused, {:submission_id => submission.id}) }
    end
  end
end
