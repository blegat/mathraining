# -*- coding: utf-8 -*-
require "spec_helper"

describe SessionsController, type: :controller, session: true do
  
  let(:user) { FactoryBot.create(:advanced_user) }
  
  context "if the user is not signed in" do      
    it { expect(response).to have_controller_post_static_path_behavior('create', :ok, {:session => {:email => user.email, :password => user.password}}) }
    it { expect(response).to have_controller_destroy_behavior(user, :access_refused) } # NB: No id is needed for sessions/destroy but we give user to make our testing method work
  end
  
  context "if the user is a simple user" do
    before { sign_in_controller(user) }

    it { expect(response).to have_controller_post_static_path_behavior('create', :danger, {:session => {:email => user.email, :password => user.password}}) }
    it { expect(response).to have_controller_destroy_behavior(user, :ok) } # NB: No id is needed for sessions/destroy but we give user to make our testing method work
  end
end


