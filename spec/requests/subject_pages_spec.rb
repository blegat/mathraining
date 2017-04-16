# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Subject pages" do

  subject { page }
  
  let(:user) { FactoryGirl.create(:user) }
  let!(:category) { FactoryGirl.create(:category) }
  let(:sub) { FactoryGirl.create(:subject) }
  let!(:exercise) { FactoryGirl.create(:exercise) }
  
  describe "visitor" do
  	describe "visit forum" do
			before do
				visit subjects_path
			end
			it { should_not have_selector('h1', text: 'Forum') }
		end
  	
  	describe "creates a subject" do
			before do
				visit new_subject_path
			end
			it { should_not have_selector('h1', text: 'Créer un sujet') }
		end
		
		describe "sees a subject" do
			before do
				visit subject_path(sub)
			end
			it { should_not have_selector('div', text: 'Contenu') }
		end
  end
  
  describe "user" do
		before do
			sign_in user
		end
		
		describe "visit forum" do
			before do
				visit subjects_path
			end
			it { should have_selector('h1', text: 'Forum') }
		end
		
		describe "creates a subject" do	
			before do
				visit new_subject_path
				fill_in "Titre", with: "Mon titre"
				fill_in "MathInput", with: "Mon message"
				select category.name, from: "Catégorie"
				click_button "Créer"
			end
			it { should have_selector('div', text: 'Mon message') }
		end
		
		# A test with javascript seems too ambitious for the moment...
		#describe "creates a subject associated to an exercise" do	
		#	before do
		#		Capybara.current_driver = Capybara.javascript_driver
		#		visit new_subject_path
		#		select exercise.chapter.section, from: "Catégorie"
		#		select exercise.chapter, from: "Chapitre"
		#		select exercise.name, from: "Exercice"
		#		fill_in "Titre", with: "Mon titre"
		#		fill_in "MathInput", with: "Mon message"
		#		click_button "Créer"
		#	end
		#	it { should have_selector('div', text: 'Mon message') }
		#end
	end

end
