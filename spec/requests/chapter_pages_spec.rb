# -*- coding: utf-8 -*-
require "spec_helper"

describe "Chapter pages", chapter: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  let(:section_fondation) { FactoryGirl.create(:fondation_section) }
  let!(:online_chapter) { FactoryGirl.create(:chapter, section: section, online: true, level: 1, position: 1) }
  let!(:online_theory) { FactoryGirl.create(:theory, chapter: online_chapter, online: true) }
  let!(:online_exercise) { FactoryGirl.create(:exercise, chapter: online_chapter, online: true) }
  let!(:offline_chapter) { FactoryGirl.create(:chapter, section: section, online: false, name: "Chapitre hors-ligne", level: 1, position: 2) }
  let!(:offline_exercise) { FactoryGirl.create(:exercise, chapter: offline_chapter, online: false) }
  let!(:offline_qcm) { FactoryGirl.create(:qcm, chapter: offline_chapter, online: false) }
  let!(:offline_item) { FactoryGirl.create(:item, question: offline_qcm) }
  let!(:offline_theory) { FactoryGirl.create(:theory, chapter: offline_chapter, online: false) }
  let!(:offline_chapter_2) { FactoryGirl.create(:chapter, section: section, online: false, name: "Autre chapitre hors-ligne", level: 3) }
  let!(:prerequisite_link_1) { FactoryGirl.create(:prerequisite, chapter: offline_chapter, prerequisite: online_chapter) }
  let!(:prerequisite_link_2) { FactoryGirl.create(:prerequisite, chapter: offline_chapter_2, prerequisite: offline_chapter) }
  let(:chapter_fondation) { FactoryGirl.create(:chapter, section: section_fondation, online: true, name: "Chapitre fondamental en ligne") }
  let(:title) { "Mon titre de chapitre" }
  let(:description) { "Ma description de chapitre" }
  let(:level) { 2 }
  let(:newtitle) { "Mon nouveau titre de chapitre" }
  let(:newdescription) { "Ma nouvelle description de chapitre" }
  let(:newlevel) { 2 }

  describe "user" do
    before { sign_in user }
    
    describe "visits an online chapter" do
      before { visit chapter_path(online_chapter) }
      it do
        should have_selector("h1", text: online_chapter.name)
      end
    end 
    
    describe "visits a full online chapter" do
      before { visit all_chapter_path(online_chapter) }
      it do
        should have_selector("h3", text: online_theory.title)
        should have_button("Marquer toute la théorie comme lue")
        should have_link("forum", href: subjects_path(:q => "cha-" + online_chapter.id.to_s))
      end
      
      describe "and mark it as read" do
        before do
          click_button "Marquer toute la théorie comme lue"
          visit chapter_theory_path(online_chapter, online_theory)
          user.reload
        end
        specify do
          expect(page).to have_button("Marquer comme non lu")
          expect(user.theories.exists?(online_theory.id)).to eq(true)
        end
      end
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visits an offline chapter" do
      before { visit chapter_path(offline_chapter) }
      specify do
        expect(page).to have_selector("h1", text: offline_chapter.name + " (en construction)")
        expect(page).to have_link("Modifier ce chapitre")
        expect(page).to have_link("Supprimer ce chapitre")
        expect(page).to have_link("Ajouter un prérequis")
        expect(page).to have_link("Supprimer", href: prerequisite_path(prerequisite_link_1))
        expect(page).to have_link("point théorique")
        expect(page).to have_link("QCM")
        expect(page).to have_no_button("Mettre ce chapitre en ligne") # Only for root
        expect { click_link("Supprimer", href: prerequisite_path(prerequisite_link_1)) }.to change(Prerequisite, :count).by(-1)
        expect { click_link("Supprimer ce chapitre") }.to change(Chapter, :count).by(-1) .and change(Question, :count).by(-2) .and change(Theory, :count).by(-1) .and change(Item, :count).by(-1)
      end
    end
    
    describe "checks chapter order" do
      before { visit chapter_path(offline_chapter) }
      it do
        should have_link "haut" # Position of chapter is 2/2
        should have_no_link "bas"
      end
      
      describe "and modifies it" do
        before do
          click_link "haut"
          offline_chapter.reload
        end
        specify do
          expect(offline_chapter.position).to eq(1)
          expect(page).to have_no_link "haut"
          expect(page).to have_link "bas"
        end
        
        describe "and modifies it back" do
          before do
            click_link "bas"
            offline_chapter.reload
          end
          specify { expect(offline_chapter.position).to eq(2) }
        end
      end
    end
    
    describe "creates a chapter" do
      before do
        visit new_section_chapter_path(section)
        fill_in "Titre", with: title
        fill_in "MathInput", with: description
        fill_in "Niveau", with: level
        click_button "Ajouter"
      end
      specify do
        expect(Chapter.order(:id).last.name).to eq(title)
        expect(Chapter.order(:id).last.position).to eq(1)
      end
      
      describe "and creates another chapter" do
        before do
          visit new_section_chapter_path(section)
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: newdescription
          fill_in "Niveau", with: newlevel
          click_button "Ajouter"
        end
        specify do
          expect(Chapter.order(:id).last.name).to eq(newtitle)
          expect(Chapter.order(:id).last.position).to eq(2)
        end
      end
    end
    
    describe "creates a chapter with empty title" do
      before do
        visit new_section_chapter_path(section)
        fill_in "Titre", with: ""
        fill_in "MathInput", with: description
        fill_in "Niveau", with: level
        click_button "Ajouter"
      end
      specify do
        expect(page).to have_error_message("Titre doit être rempli")
        expect(Chapter.order(:id).last.name).not_to eq("")
        expect(Chapter.order(:id).last.description).not_to eq(description)
      end
    end
    
    describe "updates a chapter" do
      before do
        visit edit_chapter_path(offline_chapter)
        fill_in "Titre", with: newtitle
        fill_in "MathInput", with: newdescription
        fill_in "Niveau", with: newlevel
        click_button "Modifier"
        offline_chapter.reload
      end
      specify do
        expect(offline_chapter.name).to eq(newtitle)
        expect(offline_chapter.description).to eq(newdescription)
        expect(offline_chapter.level).to eq(newlevel)
        expect(offline_chapter.position).to eq(section.chapters.where(:level => newlevel).order(:position).last.position)
      end
    end
    
    describe "updates a chapter with negative level" do
      before do
        visit edit_chapter_path(offline_chapter)
        fill_in "Titre", with: newtitle
        fill_in "MathInput", with: newdescription
        fill_in "Niveau", with: -1
        click_button "Modifier"
        offline_chapter.reload
      end
      specify do
        expect(page).to have_error_message("Niveau doit être supérieur ou égal à 1")
        expect(offline_chapter.name).not_to eq(newtitle)
        expect(offline_chapter.description).not_to eq(newdescription)
        expect(offline_chapter.level).not_to eq(-1)
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "puts a chapter online" do
      before do
        visit chapter_path(offline_chapter)
        click_button "Mettre ce chapitre en ligne"
        offline_chapter.reload
        offline_qcm.reload
        offline_exercise.reload
        offline_theory.reload
      end
      specify do
        expect(offline_chapter.online).to eq(true)
        expect(offline_qcm.online).to eq(true)
        expect(offline_exercise.online).to eq(true)
        expect(offline_theory.online).to eq(true)
      end
    end
    
    describe "tries to put online an online chapter" do
      before { visit chapter_path(online_chapter) }
      it { should have_no_button("Mettre ce chapitre en ligne") }
    end
    
    describe "tries to put online a chapter with offline prerequisites" do
      before do
        visit chapter_path(offline_chapter_2)
        click_button("Mettre ce chapitre en ligne")
        offline_chapter_2.reload
      end
      specify do
        expect(page).to have_error_message("Pour mettre un chapitre en ligne, tous ses prérequis doivent être en ligne.")
        expect(offline_chapter_2.online).to eq(false)
      end
    end
    
    describe "mark a fondation chapter as prerequisite for submissions" do
      before do
        visit chapter_path(chapter_fondation)
        click_link("Marquer comme prérequis aux soumissions")
        chapter_fondation.reload
      end
      specify do
        expect(page).to have_success_message("Ce chapitre est maintenant prérequis pour écrire une soumission.")
        expect(page).to have_content("Ce chapitre est un prérequis pour écrire une soumission à un problème.")
        expect(chapter_fondation.submission_prerequisite).to eq(true)
      end
      
      describe "and unmark it" do
        before do
          click_link("Marquer comme non prérequis aux soumissions")
          chapter_fondation.reload
        end
        specify do
          expect(page).to have_success_message("Ce chapitre n'est plus prérequis pour écrire une soumission.")
          expect(page).to have_no_content("Ce chapitre est un prérequis pour écrire une soumission à un problème.")
          expect(chapter_fondation.submission_prerequisite).to eq(false)
        end
      end
    end
  end
end
