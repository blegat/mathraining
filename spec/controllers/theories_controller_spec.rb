# -*- coding: utf-8 -*-
require "spec_helper"

describe TheoriesController, type: :controller, theory: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:chapter) { FactoryBot.create(:chapter, online: true) }
  let(:chapter2) { FactoryBot.create(:chapter, online: true) }
  let(:theory) { FactoryBot.create(:theory, chapter: chapter, online: true, position: 1) }
  let(:theory_offline) { FactoryBot.create(:theory, chapter: chapter, online: false, position: 2) }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_show_behavior(theory, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(theory, :access_refused, {:chapter_id => chapter2.id}) } # Wrong chapter
    it { expect(response).to have_controller_show_behavior(theory_offline, :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_new_behavior(:must_be_connected, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_create_behavior('theory', :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_edit_behavior(theory, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(theory, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(theory_offline, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('read', theory, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unread', theory, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', theory, :access_refused, {:new_position => 2}) }
    it { expect(response).to have_controller_put_path_behavior('put_online', theory_offline, :access_refused) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_show_behavior(theory, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(theory_offline, :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_new_behavior(:access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_create_behavior('theory', :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_edit_behavior(theory, :access_refused) }
    it { expect(response).to have_controller_update_behavior(theory, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(theory_offline, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('read', theory, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unread', theory, :ok) }
    it { expect(response).to have_controller_put_path_behavior('order', theory, :access_refused, {:new_position => 2}) }
    it { expect(response).to have_controller_put_path_behavior('put_online', theory_offline, :access_refused) }
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_show_behavior(theory, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(theory_offline, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_new_behavior(:ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_create_behavior('theory', :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_edit_behavior(theory, :ok) }
    it { expect(response).to have_controller_update_behavior(theory, :ok) }
    it { expect(response).to have_controller_destroy_behavior(theory, :ok) } # Can also delete offline theory
    it { expect(response).to have_controller_destroy_behavior(theory_offline, :ok) }
    it { expect(response).to have_controller_put_path_behavior('read', theory, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unread', theory, :ok) }
    it { expect(response).to have_controller_put_path_behavior('order', theory, :ok, {:new_position => 2}) }
    it { expect(response).to have_controller_put_path_behavior('put_online', theory_offline, :ok) }
  end
end
