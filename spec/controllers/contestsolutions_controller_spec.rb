# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestsolutionsController, type: :controller, contestsolution: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:organizer) { FactoryBot.create(:advanced_user) }
  let(:user) { FactoryBot.create(:advanced_user) }
  let(:bad_user) { FactoryBot.create(:user, rating: 180) }
  let(:contestproblem) { FactoryBot.create(:contestproblem) }
  let(:other_contestproblem) { FactoryBot.create(:contestproblem) }
  let(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, user: user) }
  
  before do
    contestproblem.contest.organizers << organizer
  end
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_show_behavior(contestsolution, :ok, {:contestproblem_id => contestproblem.id}) } # Not really ok but will automatically be redirected
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
  
  context "if the user is an organizer" do
    before do
      sign_in_controller(organizer)
      contestproblem.in_progress!
    end
    
    it { expect(response).to have_controller_create_behavior('contestsolution', :access_refused, {:contestproblem_id => contestproblem.id}) }
  end
  
  context "if the user is a participant with a solution" do
    let!(:contestsolution_other) { FactoryBot.create(:contestsolution, contestproblem: contestproblem) }
   
    before do
      sign_in_controller(user)
      contestproblem.in_progress!
    end
    
    it { expect(response).to have_controller_show_behavior(contestsolution, :access_refused, {:contestproblem_id => other_contestproblem.id}) } # Wrong contestproblem id
    it { expect(response).to have_controller_show_behavior(contestsolution, :ok, {:contestproblem_id => contestproblem.id}) } # Not really ok but will automatically be redirected
    it { expect(response).to have_controller_create_behavior('contestsolution', :ok, {:contestproblem_id => contestproblem.id}) } # Should be redirected to update existing solution
    it { expect(response).to have_controller_update_behavior(contestsolution, :ok) }
    it { expect(response).to have_controller_update_behavior(contestsolution_other, :access_refused) }
  end
  
  context "if the user cannot participate" do   
    before do
      sign_in_controller(bad_user)
      contestproblem.in_progress!
    end
    
    it { expect(response).to have_controller_create_behavior('contestsolution', :access_refused, {:contestproblem_id => contestproblem.id}) }
    it { expect(response).to have_controller_update_behavior(contestsolution, :access_refused) }
  end
end
