# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestsolutionsController, type: :controller, contestsolution: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user_other) { FactoryGirl.create(:user) }
  let(:contestproblem) { FactoryGirl.create(:contestproblem) }
  let(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false) }
  
  before do
    contestproblem.contest.organizers << user
  end
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_create_behavior('contestsolution', :access_refused, {:contestproblem_id => contestproblem.id}) }
    it { expect(response).to have_controller_update_behavior(contestsolution, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(contestsolution, :access_refused) }
  end
  
  context "if the user is an admin, not organizer" do
    before do
      sign_in_controller(admin)
      contestproblem.in_correction!
    end
    
    it { expect(response).to have_controller_put_path_behavior('reserve', contestsolution, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unreserve', contestsolution, :access_refused) }
  end
  
  context "if the user is a participant with a solution" do
    let!(:contestsolution_other) { FactoryGirl.create(:contestsolution, user: user_other, contestproblem: contestproblem, official: false) }
   
    before do
      sign_in_controller(user_other)
      contestproblem.in_progress!
    end
    
    it { expect(response).to have_controller_update_behavior(contestsolution, :access_refused) }
  end
end


