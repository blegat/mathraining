# -*- coding: utf-8 -*-
require "spec_helper"

describe TchatmessagesController, type: :controller, discussion: true do

  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:user_other) { FactoryBot.create(:user) }
  let!(:discussion) { create_discussion_between(user1, user2, "Bonjour", "Salut") }
  
  context "if the user is not involved in the discussion" do
    before { sign_in_controller(user_other) }
    
    it { expect(response).to have_controller_create_behavior('tchatmessage', :access_refused, {:discussion_id => discussion}) }
  end
end
