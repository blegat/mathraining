# -*- coding: utf-8 -*-
require "spec_helper"

describe MessagesController, type: :controller, message: true do

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:root) { FactoryBot.create(:root) }
  let(:subject) { FactoryBot.create(:subject) }
  let(:message) { FactoryBot.create(:message, subject: subject) }
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    context "and the message is his message" do
      before { message.update_attribute(:user, user) }
    
      it { expect(response).to have_controller_destroy_behavior(message, :access_refused) }
    end
    
    context "and the message is not his message" do
      it { expect(response).to have_controller_update_behavior(message, :access_refused) }
      it { expect(response).to have_controller_destroy_behavior(message, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('soft_destroy', message, :access_refused) }
    end
    
    context "and he cannot see the subject" do
      before { subject.update_attribute(:for_wepion, true) }
      
      it { expect(response).to have_controller_create_behavior('message', :access_refused, {:subject_id => subject.id}) }
    end
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    context "and the message is from another admin" do
      before { message.user.update_attribute(:role, :administrator) }
      
      it { expect(response).to have_controller_update_behavior(message, :access_refused) }
      it { expect(response).to have_controller_destroy_behavior(message, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('soft_destroy', message, :access_refused) }
    end
  end
end
