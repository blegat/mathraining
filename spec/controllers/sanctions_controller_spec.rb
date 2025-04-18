# -*- coding: utf-8 -*-
require "spec_helper"

describe SanctionsController, type: :controller, sanction: true do

  let!(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:sanction) { FactoryBot.create(:sanction) }
  
  context "if the user is not an root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_new_behavior(:access_refused, {:user_id => user.id}) }
    it { expect(response).to have_controller_create_behavior('sanction', :access_refused, {:user_id => user.id}) }
    it { expect(response).to have_controller_edit_behavior(sanction, :access_refused) }
    it { expect(response).to have_controller_update_behavior(sanction, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(sanction, :access_refused) }
  end
end
