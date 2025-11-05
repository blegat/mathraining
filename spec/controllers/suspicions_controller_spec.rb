# -*- coding: utf-8 -*-
require "spec_helper"

describe SuspicionsController, type: :controller, suspicion: true do

  let(:user) { FactoryBot.create(:user) }
  let(:corrector) { FactoryBot.create(:corrector) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:submission) { FactoryBot.create(:submission, user: corrector) }
  let(:suspicion) { FactoryBot.create(:suspicion) }
  
  context "if the user is not an root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_update_behavior(suspicion, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(suspicion, :access_refused) }
  end
  
  context "if the submission belongs to the corrector" do
    before { sign_in_controller(corrector) }
    
    it { expect(response).to have_controller_create_behavior('starproposal', :access_refused, {:submission_id => submission.id}) }
  end
  
  context "if the user is not a corrector" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('suspicion', :access_refused, {:submission_id => submission.id}) }
  end
end
