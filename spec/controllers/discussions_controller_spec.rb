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
    it "renders the error page for new" do
      get :new
      expect(response).to redirect_to signin_path
    end
  end
  
  context "if the user is not involved in the discussion" do
    before do
      sign_in_controller(user_other)
    end
    
    it "renders the error page for show" do
      get :show, params: {id: discussion.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for unread" do
      put :unread, params: {discussion_id: discussion.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
