# -*- coding: utf-8 -*-
require "spec_helper"

describe ItemsController, type: :controller, item: true do

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:question) { FactoryBot.create(:qcm, online: false) }
  let(:item) { FactoryBot.create(:item, question: question) }
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_create_behavior('item', :access_refused, {:question_id => question.id}) }
    it { expect(response).to have_controller_update_behavior(item, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(item, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('correct', item, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('uncorrect', item, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', item, :access_refused, {:new_position => 3}) }
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    context "and the question is online" do
      before { question.update_attribute(:online, true) }
      
      it { expect(response).to have_controller_create_behavior('item', :access_refused, {:question_id => question.id}) }
      it { expect(response).to have_controller_update_behavior(item, :ok) }
      it { expect(response).to have_controller_destroy_behavior(item, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('correct', item, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('uncorrect', item, :access_refused) }
      it { expect(response).to have_controller_put_path_behavior('order', item, :ok, {:new_position => 3}) }
    end
  end
end
