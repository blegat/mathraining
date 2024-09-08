# -*- coding: utf-8 -*-
require "spec_helper"

describe "prerequisite pages", prerequisite: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let!(:section) { FactoryGirl.create(:section) }
  let!(:section_fondation) { FactoryGirl.create(:fondation_section) }
  let!(:chapter_online) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:chapter_online2) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:chapter_fondation_online) { FactoryGirl.create(:chapter, section: section_fondation, online: true) }
  let!(:chapter_offline) { FactoryGirl.create(:chapter, section: section, online: false) }
  let!(:chapter_offline2) { FactoryGirl.create(:chapter, section: section, online: false) }
  let!(:chapter_fondation_offline) { FactoryGirl.create(:chapter, section: section_fondation, online: false) }

  describe "root" do
    before { sign_in root }
    
    describe "visits prerequisite graph" do
      before { visit graph_prerequisites_path }
      it do
        should have_selector("h1", text: "Modifier la structure des sections")
        should have_button("Ajouter ce lien")
        should have_button("Supprimer ce lien")
      end
      
      describe "and tries to add a prerequisite to an online chapter" do
        before do
          select chapter_offline.name, from: "add_form_prerequisite"
          select chapter_online.name, from: "add_form_chapter"
          click_button "Ajouter ce lien"
        end
        it { should have_error_message("Les prérequis d'un chapitre en ligne ne peuvent pas être modifiés.") }
      end
      
      describe "and tries to add a fondation prerequisite to a non-fondation chapter" do
        before do
          select chapter_fondation_offline.name, from: "add_form_prerequisite"
          select chapter_offline.name, from: "add_form_chapter"
          click_button "Ajouter ce lien"
        end
        it { should have_error_message("Un chapitre non-fondamental ne peut pas avoir de prérequis fondamentaux.") }
      end
      
      describe "and tries to add a non-fondation prerequisite to a fondation chapter" do
        before do
          select chapter_offline.name, from: "add_form_prerequisite"
          select chapter_fondation_offline.name, from: "add_form_chapter"
          click_button "Ajouter ce lien"
        end
        it { should have_error_message("Un chapitre fondamental ne peut pas avoir de prérequis non-fondamentaux.") }
      end
      
      describe "adds a fondation prerequisite to an offline fondation chapter" do
        before do
          select chapter_fondation_online.name, from: "add_form_prerequisite"
          select chapter_fondation_offline.name, from: "add_form_chapter"
          click_button "Ajouter ce lien"
        end
        specify { expect(chapter_fondation_offline.prerequisites.include?(chapter_fondation_online)).to equal(true) }
      end
      
      describe "adds a prerequisite to an offline chapter" do
        before do
          select chapter_offline.name, from: "add_form_prerequisite"
          select chapter_offline2.name, from: "add_form_chapter"
          click_button "Ajouter ce lien"
        end
        specify { expect(chapter_offline2.prerequisites.include?(chapter_offline)).to equal(true) }
      end
      
      describe "tries to add a link that creates a loop" do
        before do
          chapter_offline2.prerequisites << chapter_offline
          select chapter_offline2.name, from: "add_form_prerequisite"
          select chapter_offline.name, from: "add_form_chapter"
          click_button "Ajouter ce lien"
        end
        it { should have_error_message("forme la boucle") }
      end
      
      describe "tries to delete a link that does not exist" do
        before do
          select chapter_fondation_online.name, from: "delete_form_prerequisite"
          select chapter_fondation_offline.name, from: "delete_form_chapter"
          click_button "Supprimer ce lien"
        end
        it { should have_error_message("Ce lien n'existe pas") }
      end
      
      describe "tries to delete a prerequisite of an online chapter" do
        before do
          chapter_online2.prerequisites << chapter_online
          select chapter_online.name, from: "delete_form_prerequisite"
          select chapter_online2.name, from: "delete_form_chapter"
          click_button "Supprimer ce lien"
        end
        it { should have_error_message("Vous ne pouvez pas supprimer un prérequis à un chapitre en ligne.") }
      end
      
      describe "deletes a prerequisite of an offline chapter" do
        before do
          chapter_offline.prerequisites << chapter_online
          select chapter_online.name, from: "delete_form_prerequisite"
          select chapter_offline.name, from: "delete_form_chapter"
          click_button "Supprimer ce lien"
        end
        specify { expect(chapter_offline.prerequisites.count).to equal(0) }
      end
    end
  end
end
