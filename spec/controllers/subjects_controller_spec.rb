# -*- coding: utf-8 -*-
require "spec_helper"

describe SubjectsController, type: :controller, subject: true do

  let(:user) { FactoryBot.create(:user) }
  let(:subject) { FactoryBot.create(:subject) }
  let(:message) { FactoryBot.create(:message, subject: subject) }
  
  context "if the user is not connected" do
    it { expect(response).to have_controller_show_behavior(subject, :must_be_connected) }
    it { expect(response).to have_controller_new_behavior(:must_be_connected) }
    it { expect(response).to have_controller_index_behavior(:must_be_connected) }
    it { expect(response).to have_controller_get_path_behavior('unfollow', subject, :must_be_connected) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_update_behavior(subject, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(subject, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('migrate', subject, :access_refused, {migreur: 123}) }
    
    context "and he cannot see the subject" do
      before { subject.update_attribute(:for_wepion, true) }
      
      it { expect(response).to have_controller_show_behavior(subject, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('follow', subject, :access_refused) }
    end
  end
end
