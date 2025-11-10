# -*- coding: utf-8 -*-
require "spec_helper"

describe UsersController, type: :controller, user: true do
  
  let(:user1) { FactoryBot.create(:advanced_user) }
  let(:user2) { FactoryBot.create(:advanced_user) }
  let(:user_deleted) { FactoryBot.create(:user, role: :deleted) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:root) { FactoryBot.create(:root) }
  
  context "if the user is not signed in" do      
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_index_behavior(:access_refused, {:page => 3, :from => 32}) } # Strange scraping
    it { expect(response).to have_controller_show_behavior(user1, :ok) }
    it { expect(response).to have_controller_show_behavior(user_deleted, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:ok) }
    it { expect(response).to have_controller_edit_behavior(user1, :must_be_connected) }
    it { expect(response).to have_controller_create_behavior('user', :ok, {:consent1 => true, :consent2 => true}) }
    it { expect(response).to have_controller_update_behavior(user1, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('followed', :must_be_connected) }
    it { expect(response).to have_controller_get_static_path_behavior('search', :must_be_connected) }
    it { expect(response).to have_controller_get_path_behavior('activate', user1, :ok, {:key => user1.key.to_s}) }
    it { expect(response).to have_controller_get_static_path_behavior('forgot_password', :ok) }
    it { expect(response).to have_controller_post_static_path_behavior('password_forgotten', :ok, {:user => {:email => user1.email}}) }
    it { expect(response).to have_controller_patch_static_path_behavior('improve_password', :access_refused, {:user => {:password => "Nouveau7", :password_confirmation => "Nouveau7"}}) }
    it { expect(response).to have_controller_get_static_path_behavior('notifs', :must_be_connected) }
    it { expect(response).to have_controller_put_path_behavior('leave_skin', user1, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('groups', :must_be_connected) }
    it { expect(response).to have_controller_get_static_path_behavior('correctors', :ok) }
    it { expect(response).to have_controller_patch_static_path_behavior('accept_legal', :access_refused, {:consent1 => true, :consent2 => true}) }
    it { expect(response).to have_controller_put_static_path_behavior('accept_code_of_conduct', :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('follow', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unfollow', user1, :access_refused) }
    it { expect(response).to have_controller_put_static_path_behavior('set_follow_message', :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('unset_follow_message', :must_be_connected) }
    
    context "and has lost his password" do
      before { user1.update(:key => SecureRandom.urlsafe_base64, :recup_password_date_limit => DateTime.now - 2.minutes) }
      
      it { expect(response).to have_controller_get_path_behavior('recup_password', user1, :ok, {:key => user1.key.to_s}) }
      it { expect(response).to have_controller_patch_path_behavior('change_password', user1, :ok, {:key => user1.key.to_s, :user => {:password => "Nouveau7", :password_confirmation => "Nouveau7"}}) }
    end
  end
  
  context "if the user is a simple user" do
    before { sign_in_controller(user1) }

    it { expect(response).to have_controller_new_behavior(:danger) } # Should be signed out
    it { expect(response).to have_controller_edit_behavior(user1, :ok) }
    it { expect(response).to have_controller_edit_behavior(user2, :access_refused) }
    it { expect(response).to have_controller_create_behavior('user', :danger, {:consent1 => true, :consent2 => true}) } # Should be signed out
    it { expect(response).to have_controller_update_behavior(user1, :ok) }
    it { expect(response).to have_controller_update_behavior(user2, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(user1, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('followed', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('search', :ok) }
    it { expect(response).to have_controller_put_path_behavior('set_wepion', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unset_wepion', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('change_group', user1, :access_refused, {:group => "A"}) }
    it { expect(response).to have_controller_get_path_behavior('activate', user2, :ok, {:key => user2.key.to_s}) } # Can also be done when connected
    it { expect(response).to have_controller_get_static_path_behavior('forgot_password', :danger) } # Should be signed out
    it { expect(response).to have_controller_post_static_path_behavior('password_forgotten', :danger, {:user => {:email => user1.email}}) } # Should be signed out
    it { expect(response).to have_controller_patch_static_path_behavior('improve_password', :ok, {:user => {:password => "Nouveau7", :password_confirmation => "Nouveau7"}}) }
    it { expect(response).to have_controller_get_static_path_behavior('notifs', :ok) }
    it { expect(response).to have_controller_put_path_behavior('leave_skin', user1, :ok) } # Because root is in the skin of a user!
    it { expect(response).to have_controller_get_static_path_behavior('groups', :access_refused) }
    it { expect(response).to have_controller_patch_static_path_behavior('accept_legal', :ok, {:consent1 => true, :consent2 => true}) }
    it { expect(response).to have_controller_put_static_path_behavior('accept_code_of_conduct', :ok) }
    it { expect(response).to have_controller_put_path_behavior('follow', user2, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unfollow', user2, :ok) }
    it { expect(response).to have_controller_put_static_path_behavior('set_follow_message', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('unset_follow_message', :ok) }
    
    context "and has lost his password" do
      before { user1.update(:key => SecureRandom.urlsafe_base64, :recup_password_date_limit => DateTime.now - 2.minutes) }
      
      it { expect(response).to have_controller_get_path_behavior('recup_password', user1, :ok, {:key => user1.key.to_s}) } # Ok : automatic sign out
      it { expect(response).to have_controller_patch_path_behavior('change_password', user1, :ok, {:key => user1.key.to_s, :user => {:password => "Nouveau7", :password_confirmation => "Nouveau7"}}) }
    end
    
    context "and is from Wépion" do
      before { user1.update(:wepion => true) }
      
      it { expect(response).to have_controller_get_static_path_behavior('groups', :ok) }
    end
  end
  
  context "if the user is a admin" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_destroy_behavior(user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('set_administrator', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('set_wepion', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unset_wepion', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('change_group', user1, :ok, {:group => "A"}) }
    it { expect(response).to have_controller_put_path_behavior('set_corrector', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unset_corrector', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('set_can_change_name', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('unset_can_change_name', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('take_skin', user1, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('destroydata', user1, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('groups', :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('validate_names', :access_refused) }
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    it { expect(response).to have_controller_update_behavior(user1, :access_refused) }
    it { expect(response).to have_controller_update_behavior(root, :ok) }
    it { expect(response).to have_controller_destroy_behavior(user1, :ok) }
    it { expect(response).to have_controller_destroy_behavior(root, :access_refused) } # Cannot delete a root
    it { expect(response).to have_controller_put_path_behavior('set_administrator', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('set_corrector', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unset_corrector', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('set_can_change_name', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('unset_can_change_name', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('take_skin', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('leave_skin', user1, :ok) }
    it { expect(response).to have_controller_put_path_behavior('destroydata', user1, :ok) }
    it { expect(response).to have_controller_get_static_path_behavior('validate_names', :ok) }
  end
end


