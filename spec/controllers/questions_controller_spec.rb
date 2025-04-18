# -*- coding: utf-8 -*-
require "spec_helper"

describe QuestionsController, type: :controller, question: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:chapter) { FactoryBot.create(:chapter, online: true) }
  let(:chapter2) { FactoryBot.create(:chapter, online: true) }
  let(:question) { FactoryBot.create(:question, chapter: chapter, online: true) }
  let(:question_offline) { FactoryBot.create(:question, chapter: chapter, online: false) }
  let(:question2) { FactoryBot.create(:question, chapter: chapter2, online: true) }
  
  before { chapter2.prerequisites << chapter }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_show_behavior(question, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(question_offline, :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(question2, :access_refused, {:chapter_id => chapter2.id}) }
    it { expect(response).to have_controller_new_behavior(:must_be_connected, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_create_behavior('question', :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_edit_behavior(question, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(question, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(question_offline, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('edit_explanation', question, :must_be_connected) }
    it { expect(response).to have_controller_get_path_behavior('manage_items', question, :must_be_connected) }
    it { expect(response).to have_controller_patch_path_behavior('update_explanation', question, :access_refused, {:question => FactoryBot.attributes_for(:question)}) }
    it { expect(response).to have_controller_put_path_behavior('order', question, :access_refused, {:new_position => 2}) }
    it { expect(response).to have_controller_put_path_behavior('put_online', question_offline, :access_refused) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_show_behavior(question, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(question_offline, :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(question2, :access_refused, {:chapter_id => chapter2.id}) }
    it { expect(response).to have_controller_new_behavior(:access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_create_behavior('question', :access_refused, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_edit_behavior(question, :access_refused) }
    it { expect(response).to have_controller_update_behavior(question, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(question_offline, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('edit_explanation', question, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('manage_items', question, :access_refused) }
    it { expect(response).to have_controller_patch_path_behavior('update_explanation', question, :access_refused, {:question => FactoryBot.attributes_for(:question)}) }
    it { expect(response).to have_controller_put_path_behavior('order', question, :access_refused, {:new_position => 2}) }
    it { expect(response).to have_controller_put_path_behavior('put_online', question_offline, :access_refused) }
  end
  
  context "if the user is an admin" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_show_behavior(question, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(question, :access_refused, {:chapter_id => chapter2.id}) } # wrong chapter
    it { expect(response).to have_controller_show_behavior(question_offline, :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_show_behavior(question2, :ok, {:chapter_id => chapter2.id}) }
    it { expect(response).to have_controller_new_behavior(:ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_create_behavior('question', :ok, {:chapter_id => chapter.id}) }
    it { expect(response).to have_controller_edit_behavior(question, :ok) }
    it { expect(response).to have_controller_update_behavior(question, :ok) }
    it { expect(response).to have_controller_destroy_behavior(question_offline, :ok) }
    it { expect(response).to have_controller_get_path_behavior('edit_explanation', question, :ok) }
    it { expect(response).to have_controller_get_path_behavior('manage_items', question, :ok) }
    it { expect(response).to have_controller_patch_path_behavior('update_explanation', question, :ok, {:question => FactoryBot.attributes_for(:question)}) }
    it { expect(response).to have_controller_put_path_behavior('order', question, :ok, {:new_position => 2}) }
    it { expect(response).to have_controller_put_path_behavior('put_online', question_offline, :ok) }
  end
end
