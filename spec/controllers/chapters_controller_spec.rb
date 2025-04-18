# -*- coding: utf-8 -*-
require "spec_helper"

describe ChaptersController, type: :controller, chapter: true do

  let(:root) { FactoryBot.create(:root) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:section) { FactoryBot.create(:section) }
  let(:online_chapter) { FactoryBot.create(:chapter, online: true) }
  let(:offline_chapter) { FactoryBot.create(:chapter, online: false) }
  let(:theory) { FactoryBot.create(:theory, chapter: online_chapter, online: true) }
  let(:question) { FactoryBot.create(:exercise, chapter: online_chapter, online: true) }
  let!(:offline_question) { FactoryBot.create(:exercise, chapter: offline_chapter, online: false) } # So that offline_chapter can be put online
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_show_behavior(online_chapter, :ok) }
    it { expect(response).to have_controller_show_behavior(offline_chapter, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:must_be_connected, {:section_id => section.id}) }
    it { expect(response).to have_controller_create_behavior('chapter', :access_refused, {:section_id => section.id}) }
    it { expect(response).to have_controller_edit_behavior(online_chapter, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(online_chapter, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(offline_chapter, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('all', online_chapter, :ok) }
    it { expect(response).to have_controller_get_path_behavior('all', offline_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('put_online', offline_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('mark_submission_prerequisite', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unmark_submission_prerequisite', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('read', online_chapter, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('stats', :ok) }
    
    it "redirects to new format for chapter type 0" do
      get :show, params: {id: online_chapter.id, type: 0}
      expect(response).to redirect_to chapter_path(online_chapter)
    end
    
    it "redirects to new format for chapter type 10" do
      get :show, params: {id: online_chapter.id, type: 10}
      expect(response).to redirect_to all_chapter_path(online_chapter)
    end
    
    it "redirects to new format for chapter type 1" do
      get :show, params: {id: online_chapter.id, type: 1, which: theory.id}
      expect(response).to redirect_to chapter_theory_path(online_chapter, theory)
    end
    
    it "redirects to new format for chapter type 5" do
      get :show, params: {id: online_chapter.id, type: 5, which: question.id}
      expect(response).to redirect_to chapter_question_path(online_chapter, question)
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_show_behavior(online_chapter, :ok) }
    it { expect(response).to have_controller_show_behavior(offline_chapter, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:access_refused, {:section_id => section.id}) }
    it { expect(response).to have_controller_create_behavior('chapter', :access_refused, {:section_id => section.id}) }
    it { expect(response).to have_controller_edit_behavior(online_chapter, :access_refused) }
    it { expect(response).to have_controller_update_behavior(online_chapter, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(offline_chapter, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('all', online_chapter, :ok) }
    it { expect(response).to have_controller_get_path_behavior('all', offline_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('put_online', offline_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('mark_submission_prerequisite', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unmark_submission_prerequisite', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('read', online_chapter, :ok) }
    it { expect(response).to have_controller_put_path_behavior('read', offline_chapter, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('stats', :ok) }
  end
  
  context "if the user is an admin (not a root)" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_show_behavior(offline_chapter, :ok) }
    it { expect(response).to have_controller_new_behavior(:ok, {:section_id => section.id}) }
    it { expect(response).to have_controller_create_behavior('chapter', :ok, {:section_id => section.id}) }
    it { expect(response).to have_controller_edit_behavior(online_chapter, :ok) }
    it { expect(response).to have_controller_update_behavior(online_chapter, :ok) }
    it { expect(response).to have_controller_destroy_behavior(offline_chapter, :ok) }
    it { expect(response).to have_controller_destroy_behavior(online_chapter, :access_refused) }
    it { expect(response).to have_controller_get_path_behavior('all', offline_chapter, :ok) }
    it { expect(response).to have_controller_put_path_behavior('put_online', offline_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('mark_submission_prerequisite', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unmark_submission_prerequisite', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', online_chapter, :ok) }
    it { expect(response).to have_controller_put_path_behavior('read', online_chapter, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('stats', :ok) }
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    it { expect(response).to have_controller_put_path_behavior('put_online', offline_chapter, :ok) }
    it { expect(response).to have_controller_put_path_behavior('put_online', online_chapter, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('mark_submission_prerequisite', online_chapter, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unmark_submission_prerequisite', online_chapter, :ok) }
    it { expect(response).to have_controller_put_path_behavior('read', online_chapter, :access_refused) }
  end
end
