# -*- coding: utf-8 -*-
require "spec_helper"

describe PrivacypoliciesController, type: :controller, privacypolicy: true do

  let(:root) { FactoryBot.create(:root) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:privacypolicy) { FactoryBot.create(:privacypolicy, online: false) }
  
  context "if the user is not a root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_show_behavior(privacypolicy, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_edit_behavior(privacypolicy, :access_refused) }
    it { expect(response).to have_controller_update_behavior(privacypolicy, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(privacypolicy, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('edit_description', privacypolicy, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('put_online', privacypolicy, :access_refused) }
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    it { expect(response).to have_controller_show_behavior(privacypolicy, :access_refused) } # Cannot show an offline privacy policy
    
    context "and the policy is online" do
      before { privacypolicy.update_attribute(:online, true) }
      
      it { expect(response).to have_controller_edit_behavior(privacypolicy, :access_refused) }
      it { expect(response).to have_controller_update_behavior(privacypolicy, :access_refused) }
      it { expect(response).to have_controller_destroy_behavior(privacypolicy, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('put_online', privacypolicy, :access_refused) }
    end
  end
end
