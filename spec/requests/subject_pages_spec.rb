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
  let!(:sub) { FactoryGirl.create(:subject) }
  let!(:exercise) { FactoryGirl.create(:exercise) }
  
  describe "visitor" do
  	describe "visit forum" do
			before { visit subjects_path }
			it { should_not have_selector('h1', text: 'Forum') }
		end
  	
  	describe "creates a subject" do
			before { visit new_subject_path }
			it { should_not have_selector('h1', text: 'Créer un sujet') }
		end
		
		describe "sees a subject" do
			before { visit subject_path(sub) }
			it { should_not have_selector('div', text: 'Contenu') }
		end
  end
  
  describe "user" do
		before { sign_in user }
		
		describe "visit forum" do
			before { visit subjects_path }
			it { should have_selector('h1', text: 'Forum') }
		end
		
		describe "creates a subject" do
			before { visit subjects_path }
			it { should have_link("Créer un sujet") }
			
			describe "on the page" do
				before { click_link("Créer un sujet") }
				it { should have_selector('h1', text: 'Créer un sujet') }
				
				describe "after submission" do
					before { create_subject(category) }
					it { should have_selector('div', text: 'Mon message') }
				end
			end
		end
		
		describe "edits/deletes his subject" do
			before do
				sub.user = user
				sub.save
				visit subject_path(sub)
			end
			it { should have_link('Modifier ce sujet') }
			it { should_not have_link('Supprimer ce sujet') }
			
			describe "on the page" do
				before { click_link("Modifier ce sujet") }
				it { should have_selector('h1', text: 'Modifier un sujet') }
				
				describe "after submission" do
					before { update_subject(sub) }
					it { should have_selector('div', text: 'Mon nouveau message') }
				end
			end
		end
		
		describe "edits the subject of someone else" do
			before { visit subject_path(sub) }
			it { should_not have_link("Modifier ce sujet") }
			
			describe "on the page" do
				before { visit edit_subject_path(sub) }
				it { should_not have_selector('h1', text: 'Modifier un sujet') }
			end
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
  	before { sign_in admin }
  	
  	describe "edits/deletes the subject of a student" do
  		before { visit subject_path(sub) }
  		it { should have_link('Modifier ce sujet') }
			it { should have_link('Supprimer ce sujet') }
			
			specify do
				expect { click_link('Supprimer ce sujet') }.to change(Subject, :count).by(-1)
			end	
			
			describe "on the page" do
				before { click_link("Modifier ce sujet") }
				it { should have_selector('h1', text: 'Modifier un sujet') }
				
				describe "after submission" do
					before { update_subject(sub) }
					it { should have_selector('div', text: 'Mon nouveau message') }
				end
			end
  	end
  	
  	describe "edits/deletes his subject" do
  		before do
  			sub.user = admin
  			sub.save
  			visit subject_path(sub)
  		end
  		it { should have_link('Modifier ce sujet') }
			it { should have_link('Supprimer ce sujet') }
			
			specify do
				expect { click_link('Supprimer ce sujet') }.to change(Subject, :count).by(-1)
			end	
			
			describe "on the page" do
				before { click_link("Modifier ce sujet") }
				it { should have_selector('h1', text: 'Modifier un sujet') }
				
				describe "after submission" do
					before { update_subject(sub) }
					it { should have_selector('div', text: 'Mon nouveau message') }
				end
			end
  	end
  	
  	describe "edits/deletes the subject of another admin" do
  		before do
  			sub.user = other_admin
  			sub.save
  			visit subject_path(sub)
  		end
  		it { should_not have_link('Modifier ce sujet') }
			it { should_not have_link('Supprimer ce sujet') }
			
			describe "on the page" do
				before { visit edit_subject_path(sub) }
				it { should_not have_selector('h1', text: 'Modifier un sujet') }
			end
  	end
  end
  
  describe "root" do
  	before { sign_in root }
  	
  	describe "edits/deletes the subject of another root" do
  		before do
  			sub.user = other_root
  			sub.save
  			visit subject_path(sub)
  		end
  		it { should have_link('Modifier ce sujet') }
			it { should have_link('Supprimer ce sujet') }
			
			specify do
				expect { click_link('Supprimer ce sujet') }.to change(Subject, :count).by(-1)
			end	
			
			describe "on the page" do
				before { click_link("Modifier ce sujet") }
				it { should have_selector('h1', text: 'Modifier un sujet') }
				
				describe "after submission" do
					before { update_subject(sub) }
					it { should have_selector('div', text: 'Mon nouveau message') }
				end
			end
  	end
  end

end
