# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Message pages" do

  subject { page }
  
  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:sub) { FactoryGirl.create(:subject) }
  let(:mes) { FactoryGirl.create(:message) }
  let(:mes_user) { FactoryGirl.create(:message, user: user) }
  let(:mes_admin) { FactoryGirl.create(:message, user: admin) }
  let(:mes_other_admin) { FactoryGirl.create(:message, user: other_admin) }
  let(:mes_other_root) { FactoryGirl.create(:message, user: other_root) }
  let(:content) { "Ma réponse" }
  let(:newcontent) { "Ma nouvelle réponse" }
  
  describe "visitor" do
		describe "creates a message" do
			before { visit new_subject_message_path(sub) }
			it { should_not have_selector('h1', text: 'Répondre') }
		end
  end
	
	describe "user" do
		before { sign_in user }
		describe "creates a message" do
			before { visit subject_path(sub) }
			it { should have_link('Répondre') }
			
			describe "on the page" do
				before { click_link('Répondre') }
				it { should have_selector('h1', text: 'Répondre') }
				
				describe "after submission" do
					before { create_message(sub, content) }
					it { should have_selector('div', text: content) }
				end
			end
		end
		
		describe "edits/deletes his message" do
			before { visit subject_path(mes_user.subject) }
			it { should have_link('Modifier ce message') }
			it { should_not have_link('Supprimer ce message') }
			
			describe "on the page" do
				before { click_link('Modifier ce message') }
				it { should have_selector('h1', text: 'Modifier un message') }
				
				describe "after submission" do
					before { update_message(mes_user.subject, mes_user, newcontent) }
					it { should have_selector('div', text: newcontent) }
				end
			end
		end
		
		describe "edits the message of someone else" do
			before { visit subject_path(mes.subject) }
			it { should_not have_link("Modifier ce message") }
			
			describe "on the page" do
				before { visit edit_subject_message_path(mes.subject, mes) }
				it { should_not have_selector('h1', text: 'Modifier un message') }
			end
		end
	end
	
	describe "admin" do
		before { sign_in admin }
		
		describe "edits/deletes the message of a student" do
			before { visit subject_path(mes.subject) }
			it { should have_link('Modifier ce message') }
			it { should have_link('Supprimer ce message') }
			
			specify do
				expect { click_link('Supprimer ce message') }.to change(Message, :count).by(-1)
			end	
			
			describe "on the page" do
				before { click_link('Modifier ce message') }
				it { should have_selector('h1', text: 'Modifier un message') }
				
				describe "after submission" do
					before { update_message(mes.subject, mes, newcontent) }
					it { should have_selector('div', text: newcontent) }
				end
			end
		end
		
		describe "edits/deletes his message" do
			before { visit subject_path(mes_admin.subject) }
			it { should have_link('Modifier ce message') }
			it { should have_link('Supprimer ce message') }
			
			specify do
				expect { click_link('Supprimer ce message') }.to change(Message, :count).by(-1)
			end	
			
			describe "on the page" do
				before { click_link('Modifier ce message') }
				it { should have_selector('h1', text: 'Modifier un message') }
				
				describe "after submission" do
					before { update_message(mes_admin.subject, mes_admin, newcontent) }
					it { should have_selector('div', text: newcontent) }
				end
			end
		end
		
		describe "edits/delete the message of another admin" do
			before { visit subject_path(mes_other_admin.subject) }
			it { should_not have_link("Modifier ce message") }
			it { should_not have_link("Supprimer ce message") }
			
			describe "on the page" do
				before { visit edit_subject_message_path(mes_other_admin.subject, mes_other_admin) }
				it { should_not have_selector('h1', text: 'Modifier un message') }
			end
		end
	end
	
	describe "root" do
		before { sign_in root }
		describe "edits/deletes the message of another root" do
			before { visit subject_path(mes_other_root.subject) }
			it { should have_link('Modifier ce message') }
			it { should have_link('Supprimer ce message') }
			
			specify do
				expect { click_link('Supprimer ce message') }.to change(Message, :count).by(-1)
			end	
			
			describe "on the page" do
				before { click_link('Modifier ce message') }
				it { should have_selector('h1', text: 'Modifier un message') }
				
				describe "after submission" do
					before { update_message(mes_other_root.subject, mes_other_root, newcontent) }
					it { should have_selector('div', text: newcontent) }
				end
			end
		end
	end
end
