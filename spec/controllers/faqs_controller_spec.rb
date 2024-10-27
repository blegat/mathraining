# -*- coding: utf-8 -*-
require "spec_helper"

describe FaqsController, type: :controller, faq: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:faq) { FactoryGirl.create(:faq) }
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('faq', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(faq, :access_refused) }
    it { expect(response).to have_controller_update_behavior(faq, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(faq, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', faq, :access_refused, {:new_position => 1}) }
  end
end
