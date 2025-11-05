# -*- coding: utf-8 -*-
require "spec_helper"

describe DiscussionsController, type: :controller, discussion: true do

  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:user_other) { FactoryBot.create(:user) }
  let!(:discussion) { create_discussion_between(user1, user2, "Salut", "Hello") }

  context "if the user is not signed in" do
    it { expect(response).to have_controller_new_behavior(:must_be_connected) }
  end
  
  context "if the user is not involved in the discussion" do
    before { sign_in_controller(user_other) }
    
    it { expect(response).to have_controller_show_behavior(discussion, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unread', discussion, :access_refused) }
  end
end
