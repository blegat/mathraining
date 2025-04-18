# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestcorrectionsController, type: :controller, contestcorrection: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:contestproblem) { FactoryBot.create(:contestproblem) }
  let(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, official: false) }
  let(:contestcorrection) { contestsolution.contestcorrection }
  let(:contestsolution_official) { contestproblem.contestsolutions.where(:official => true).first }
  
  before do
    contestproblem.contest.organizers << user
    contestsolution.update_attribute(:reservation, user.id)
    contestsolution_official.update_attribute(:reservation, user.id)
  end
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_update_behavior(contestcorrection, :access_refused) }
  end
  
  context "if the user is not an organizer" do
    before do
      sign_in_controller(admin)
      contestproblem.in_correction!
    end
    
    it { expect(response).to have_controller_update_behavior(contestcorrection, :access_refused) }
  end
  
  context "if the user is an organizer" do
    before { sign_in_controller(user) }
    
    context "and the problem is in progress" do
      before { contestproblem.in_progress! }
      it { expect(response).to have_controller_update_behavior(contestcorrection, :danger) }
    end
    
    context "and the problem is in correction" do
      before { contestproblem.in_correction! }
      it { expect(response).to have_controller_update_behavior(contestcorrection, :ok) }
    end
    
    context "and the problem is in recorrection" do
      before { contestproblem.in_recorrection! }
      it { expect(response).to have_controller_update_behavior(contestcorrection, :ok) }
    end
    
    context "and the solution is the official one" do
      before { contestproblem.in_progress! }
      it { expect(response).to have_controller_update_behavior(contestsolution_official.contestcorrection, :ok) }
    end
    
    context "and the solution was not reserved" do
      before do
        contestproblem.in_correction!
        contestsolution.update_attribute(:reservation, 0)
      end
      it { expect(response).to have_controller_update_behavior(contestcorrection, :danger) }
    end
  end
end


