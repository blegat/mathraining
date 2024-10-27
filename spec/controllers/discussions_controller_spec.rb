# -*- coding: utf-8 -*-
require "spec_helper"

describe DiscussionsController, type: :controller, discussion: true do

  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:user_other) { FactoryGirl.create(:user) }
  let!(:discussion) { Discussion.create }
  let!(:link1) { Link.create(discussion: discussion, user: user1) }
  let!(:link2) { Link.create(discussion: discussion, user: user2) }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_new_behavior(:must_be_connected) }
  end
  
  context "if the user is not involved in the discussion" do
    before { sign_in_controller(user_other) }
    
    it { expect(response).to have_controller_show_behavior(discussion, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unread', discussion, :access_refused) }
  end
end
