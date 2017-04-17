# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Subject pages" do

  subject { page }
  
  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
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
		
		describe "update his subject" do
			before do
				sub.user = user
				sub.save
				visit edit_subject_path(sub)
				fill_in "Titre", with: "Mon nouveau titre"
				fill_in "MathInput", with: "Mon nouveau message"
				click_button "Editer"
			end
			it { should have_selector('div', text: 'Mon nouveau message') }
		end
		
		describe "sees a subject" do
			before do
				visit subject_path(sub)
			end
			it { should have_selector('div', text: 'Contenu') }
		end
		
		describe "edits his subject" do
			before do
				sub.user = user
				sub.save
				visit edit_subject_path(sub)
			end
			it { should have_selector('h1', text: 'Modifier le sujet') }
		end
		
		describe "edits a subject of someone else" do
			before do
				visit edit_subject_path(sub)
			end
			it { should_not have_selector('h1', text: 'Modifier le sujet') }
		end
		
		describe "tries do edit/delete his subject" do
			before do
				sub.user = user
				sub.save
				visit subject_path(sub)
			end
			it { should_not have_link('Supprimer ce sujet') }
			it { should have_link('Modifier ce sujet') }
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
  
  describe "admin" do
  	before do
  		sign_in admin
  	end
  	
  	describe "edits the subject of a student" do
  		before do
  			visit edit_subject_path(sub)
  		end
  		it { should have_selector('h1', text: 'Modifier le sujet') }
  	end
  	
  	describe "edits his subject" do
  		before do
  			sub.user = admin
  			sub.save
  			visit edit_subject_path(sub)
  		end
  		it { should have_selector('h1', text: 'Modifier le sujet') }
  	end
  	
  	describe "edits the subject of another admin" do
  		before do
  			sub.user = other_admin
  			sub.save
  			visit edit_subject_path(sub)
  		end
  		it { should_not have_selector('h1', text: 'Modifier le sujet') }
  	end
  	
  	describe "tries do edit/delete the subject of a student" do
			before do
				visit subject_path(sub)
			end
			it { should have_link('Supprimer ce sujet') }
			it { should have_link('Modifier ce sujet') }
		end
		
		describe "tries do edit/delete the subject of a student" do
			before do
				visit subject_path(sub)
			end
			it { should have_link('Supprimer ce sujet') }
			it { should have_link('Modifier ce sujet') }
		end
		
		describe "tries do edit/delete his subject" do
			before do
				sub.user = admin
				sub.save
				visit subject_path(sub)
			end
			it { should have_link('Supprimer ce sujet') }
			it { should have_link('Modifier ce sujet') }
		end
		
		describe "tries do edit/delete the subject of another admin" do
			before do
				sub.user = other_admin
				sub.save
				visit subject_path(sub)
			end
			it { should_not have_link('Supprimer ce sujet') }
			it { should_not have_link('Modifier ce sujet') }
		end
  end
  
  describe "root" do
  	before do
  		sign_in root
  	end
  	
  	describe "edits the subject of a student" do
  		before do
  			visit edit_subject_path(sub)
  		end
  		it { should have_selector('h1', text: 'Modifier le sujet') }
  	end
  	
  	describe "edits his subject" do
  		before do
  			sub.user = root
  			sub.save
  			visit edit_subject_path(sub)
  		end
  		it { should have_selector('h1', text: 'Modifier le sujet') }
  	end
  	
  	describe "edits the subject of another root" do
  		before do
  			sub.user = other_root
  			sub.save
  			visit edit_subject_path(sub)
  		end
  		it { should have_selector('h1', text: 'Modifier le sujet') }
  	end
		
		describe "tries do edit/delete the subject of another root" do
			before do
				sub.user = other_root
				sub.save
				visit subject_path(sub)
			end
			it { should have_link('Supprimer ce sujet') }
			it { should have_link('Modifier ce sujet') }
		end
  end

end
