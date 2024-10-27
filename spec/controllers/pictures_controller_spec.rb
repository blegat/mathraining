# -*- coding: utf-8 -*-
require "spec_helper"

describe PicturesController, type: :controller, picture: true do

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:picture) { FactoryGirl.create(:picture, user: root) }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_get_path_behavior('image', picture, :access_refused) } # Without key
    it { expect(response).to have_controller_get_path_behavior('image', picture, :access_refused, {:key => picture.access_key + "WRONG"}) } # Wrong key
    it { expect(response).to have_controller_get_path_behavior('image', picture, :ok, {:key => picture.access_key}) } # Correct key
    
    it { expect(response).to have_controller_index_behavior(:must_be_connected) }
    it { expect(response).to have_controller_show_behavior(picture, :must_be_connected) }
    it { expect(response).to have_controller_new_behavior(:must_be_connected) }
  end
  
  context "if the user is not an admin" do
    before { sign_in_controller(user) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_show_behavior(picture, :access_refused) }
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('picture', :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(picture, :access_refused) }
  end
  
  context "if the user is not a root (and not the author)" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_show_behavior(picture, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(picture, :access_refused) }
  end
end
