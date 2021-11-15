# -*- coding: utf-8 -*-
require "spec_helper"

describe "Chapter pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  let!(:online_chapter) { FactoryGirl.create(:chapter, section: section, online: true, level: 1, position: 1) }
  let!(:online_theory) { FactoryGirl.create(:theory, chapter: online_chapter, online: true) }
  let!(:online_exercise) { FactoryGirl.create(:exercise, chapter: online_chapter, online: true) }
  let!(:offline_chapter) { FactoryGirl.create(:chapter, section: section, online: false, name: "Chapitre hors-ligne", level: 1, position: 2) }
  let!(:offline_exercise) { FactoryGirl.create(:exercise, chapter: offline_chapter, online: false) }
  let!(:offline_qcm) { FactoryGirl.create(:qcm, chapter: offline_chapter, online: false) }
  let!(:offline_item) { FactoryGirl.create(:item, question: offline_qcm) }
  let!(:offline_theory) { FactoryGirl.create(:theory, chapter: offline_chapter, online: false) }
  let!(:offline_chapter_2) { FactoryGirl.create(:chapter, section: section, online: false, name: "Autre chapitre hors-ligne", level: 3) }
  let!(:prerequisite_link) { FactoryGirl.create(:prerequisite, chapter: offline_chapter_2, prerequisite: offline_chapter) }
  let(:title) { "Mon titre de chapitre" }
  let(:description) { "Ma description de chapitre" }
  let(:level) { 2 }
  let(:newtitle) { "Mon nouveau titre de chapitre" }
  let(:newdescription) { "Ma nouvelle description de chapitre" }
  let(:newlevel) { 2 }
  
  describe "visitor" do
    describe "visits an online chapter" do
      before { visit chapter_path(online_chapter) }
      it { should have_selector("h1", text: online_chapter.name) }
    end
    
    describe "visits an offline chapter" do
      before { visit chapter_path(offline_chapter) }
      it { should have_content(error_access_refused) }
    end
  end

  describe "user" do
    before { sign_in user }
    
    describe "visits an offline chapter" do
      before { visit chapter_path(offline_chapter) }
      it { should have_content(error_access_refused) }
    end
    
    describe "visits an online chapter" do
      before { visit chapter_path(online_chapter) }
      it do
        should have_selector("h1", text: online_chapter.name)
        should have_no_link("Modifier les prérequis")
        should have_no_link("Modifier ce chapitre")
        should have_no_link("point théorique")
        should have_no_link("QCM")
      end
    end 
    
    describe "visits a full online chapter" do
      before { visit chapter_path(online_chapter, :type => 10) }
      it do
        should have_selector("h3", text: online_theory.title)
        should have_button("Marquer toute la théorie comme lue")
      end
      
      describe "and mark it as read" do
        before do
          click_button "Marquer toute la théorie comme lue"
          visit chapter_path(online_chapter, :type => 1, :which => online_theory)
          user.reload
        end
        it { should have_button("Marquer comme non lu") }
        specify { expect(user.theories.exists?(online_theory.id)).to eq(true) }
      end
    end
    
    describe "tries to create a chapter" do
      before { visit new_section_chapter_path(section) }
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to edit a chapter" do
      before { visit edit_chapter_path(offline_chapter) }
      it { should have_content(error_access_refused) }
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visits an offline chapter" do
      before { visit chapter_path(offline_chapter) }
      it do
        should have_selector("h1", text: offline_chapter.name + " (en construction)")
        should have_link("Modifier ce chapitre")
        should have_link("Supprimer ce chapitre")
        should have_link("Modifier les prérequis")
        should have_link("point théorique")
        should have_link("QCM")
        should have_button("Mettre ce chapitre en ligne")
      end
      specify { expect { click_link("Supprimer ce chapitre") }.to change(Chapter, :count).by(-1) .and change(Question, :count).by(-2) .and change(Theory, :count).by(-1) .and change(Item, :count).by(-1) }
    end
    
    describe "visits warning page to put online" do
      before { visit chapter_warning_path(offline_chapter) }
      it { should have_selector("h1", text: "Mise en ligne") }
      it { should have_button("Mettre ce chapitre en ligne") }
      
      describe "and puts it online" do
        before do
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
    end
    
    describe "tries to put online an online chapter" do
      before { visit chapter_warning_path(online_chapter) }
      it do
        should have_no_selector("h1", text: "Mise en ligne")
        should have_no_button("Mettre ce chapitre en ligne")
      end
    end
    
    describe "tries to put online a chapter with offline prerequisites" do
      before { visit chapter_warning_path(offline_chapter_2) }
      it do
        should have_no_selector("h1", text: "Mise en ligne")
        should have_error_message("Pour mettre un chapitre en ligne, tous ses prérequis doivent être en ligne.")
        should have_button("Mettre ce chapitre en ligne") # Redirects to the chapter page with this button (even if we cannot use it)
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
        specify { expect(offline_chapter.position).to eq(1) }
        it do
          should have_no_link "haut"
          should have_link "bas"
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
    
    describe "edits a chapter" do
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
  end
end
