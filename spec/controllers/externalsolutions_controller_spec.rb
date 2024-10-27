# -*- coding: utf-8 -*-
require "spec_helper"

describe ExternalsolutionsController, type: :controller, externalsolution: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:problem) { FactoryGirl.create(:problem) }
  let(:externalsolution) { FactoryGirl.create(:externalsolution) }
  
  context "if the user is not an signed in" do 
    it { expect(response).to have_controller_create_behavior('externalsolution', :access_refused, {:problem_id => problem.id}) }
    it { expect(response).to have_controller_update_behavior(externalsolution, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(externalsolution, :access_refused) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_create_behavior('externalsolution', :access_refused, {:problem_id => problem.id}) }
    it { expect(response).to have_controller_update_behavior(externalsolution, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(externalsolution, :access_refused) }
  end
end
