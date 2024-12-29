# -*- coding: utf-8 -*-
require "spec_helper"

describe PuzzlesController, type: :controller, puzzle: true do

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:puzzle) { FactoryGirl.create(:puzzle) }
  
  context "if the user is not signed in" do
    it { expect(response).to have_controller_new_behavior(:must_be_connected) }
    it { expect(response).to have_controller_index_behavior(:must_be_connected) }
    it { expect(response).to have_controller_create_behavior('puzzle', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(puzzle, :must_be_connected) }
    it { expect(response).to have_controller_update_behavior(puzzle, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(puzzle, :access_refused) }
    it { expect(response).to have_controller_get_static_path_behavior('main', :must_be_connected) }
    # it { expect(response).to have_controller_get_js_path_behavior('attempt', puzzle, :must_be_connected, {:attempt => "HELLO"}) } # Doesn't work correctly!
    it { expect(response).to have_controller_put_path_behavior('order', puzzle, :access_refused, {:new_position => 2}) }
  end
  
  context "if the user is not a root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_new_behavior(:access_refused) }
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_create_behavior('puzzle', :access_refused) }
    it { expect(response).to have_controller_edit_behavior(puzzle, :access_refused) }
    it { expect(response).to have_controller_update_behavior(puzzle, :access_refused) }
    it { expect(response).to have_controller_destroy_behavior(puzzle, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('order', puzzle, :access_refused, {:new_position => 2}) }
    
    context "and we are before the start date" do
      before { travel_to Puzzle.start_date - 10.minutes }
      
      it { expect(response).to have_controller_get_static_path_behavior('main', :access_refused) }
      # it { expect(response).to have_controller_get_js_path_behavior('attempt', puzzle, :access_refused, {:attempt => "HELLO"}) } # Doesn't work correctly!
    end
    
    context "and we are between the start and end dates" do
      before { travel_to Puzzle.start_date + 10.minutes }
      
      it { expect(response).to have_controller_get_static_path_behavior('main', :ok) }
      # it { expect(response).to have_controller_get_js_path_behavior('attempt', puzzle, :ok, {:attempt => "HELLO"}) } # Doesn't work correctly!
    end
    
    context "and we are after the end date" do
      before { travel_to Puzzle.end_date + 10.minutes }
      
      it { expect(response).to have_controller_get_static_path_behavior('main', :ok) }
      # it { expect(response).to have_controller_get_js_path_behavior('attempt', puzzle, :access_refused, {:attempt => "HELLO"}) } # Doesn't work correctly!
    end
  end
  
  context "if the user is a root" do
    before { sign_in_controller(root) }
    
    it { expect(response).to have_controller_index_behavior(:ok) }
    it { expect(response).to have_controller_edit_behavior(puzzle, :ok) }
    it { expect(response).to have_controller_update_behavior(puzzle, :ok) }
    
    context "and we are before the start date" do
      before { travel_to Puzzle.start_date - 10.minutes }
      
      it { expect(response).to have_controller_new_behavior(:ok) }
      it { expect(response).to have_controller_create_behavior('puzzle', :ok) }
      it { expect(response).to have_controller_destroy_behavior(puzzle, :ok) }
      it { expect(response).to have_controller_get_static_path_behavior('main', :ok) }
      # it { expect(response).to have_controller_get_js_path_behavior('attempt', puzzle, :ok, {:attempt => "HELLO"}) } # Doesn't work correctly!
      it { expect(response).to have_controller_put_path_behavior('order', puzzle, :ok, {:new_position => 2}) }
    end
    
    context "and we are between the start and end dates" do
      before { travel_to Puzzle.start_date + 10.minutes }
      
      it { expect(response).to have_controller_new_behavior(:ok) }
      it { expect(response).to have_controller_create_behavior('puzzle', :ok) }
      it { expect(response).to have_controller_destroy_behavior(puzzle, :ok) }
      it { expect(response).to have_controller_get_static_path_behavior('main', :ok) }
      # it { expect(response).to have_controller_get_js_path_behavior('attempt', puzzle, :ok, {:attempt => "HELLO"}) } # Doesn't work correctly!
      it { expect(response).to have_controller_put_path_behavior('order', puzzle, :ok, {:new_position => 2}) }
    end
    
    context "and we are after the end date" do
      before { travel_to Puzzle.end_date + 10.minutes }
      
      it { expect(response).to have_controller_new_behavior(:access_refused) }
      it { expect(response).to have_controller_create_behavior('puzzle', :access_refused) }
      it { expect(response).to have_controller_destroy_behavior(puzzle, :access_refused) }
      it { expect(response).to have_controller_get_static_path_behavior('main', :ok) }
      # it { expect(response).to have_controller_get_js_path_behavior('attempt', puzzle, :access_refused, {:attempt => "HELLO"}) } # Doesn't work correctly!
      it { expect(response).to have_controller_put_path_behavior('order', puzzle, :access_refused, {:new_position => 2}) }
    end
  end
end
