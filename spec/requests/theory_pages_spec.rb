# -*- coding: utf-8 -*-
require "spec_helper"

describe "Theory pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:empty_chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:online_theory) { FactoryGirl.create(:theory, chapter: chapter, online: true, position: 1) }
  let!(:online_theory_2) { FactoryGirl.create(:theory, chapter: chapter, online: true, title: "Autre titre", content: "Autre contenu", position: 2) }
  let!(:offline_theory) { FactoryGirl.create(:theory, chapter: chapter, online: false, position: 3) }
  let(:newtitle) { "Mon nouveau titre de point théorique" }
  let(:newcontent) { "Mon nouveau point théorique" }
  let(:newtitle2) { "Mon nouveau titre de point théorique 2" }
  let(:newcontent2) { "Mon nouveau point théorique 2" }
  
  describe "visitor" do
    describe "visits online theory" do
      before { visit chapter_path(chapter, :type => 1, :which => online_theory.id) }
      it { should have_selector("h3", text: online_theory.title) }
    end
    
    describe "visits offline theory" do
      before { visit chapter_path(chapter, :type => 1, :which => offline_theory.id) }
      it { should_not have_selector("h3", text: offline_theory.title) }
    end
  end
  
  describe "user" do
    before { sign_in user }
    
    describe "visits online theory" do
      before { visit chapter_path(chapter, :type => 1, :which => online_theory_2.id) }
      it { should have_selector("h3", text: online_theory_2.title) }
      it { should_not have_link "bas" }
      it { should_not have_link "haut" }
      it { should have_button "Marquer comme lu" }
      it { should_not have_button "Marquer comme non lu" }
      
      describe "and mark it as read" do
        before do
          click_button "Marquer comme lu"
          online_theory_2.reload
          user.reload
        end
        it { should_not have_button "Marquer comme lu" }
        it { should have_button "Marquer comme non lu" }
        specify { expect(user.theories.exists?(online_theory_2.id)).to eq(true) }
        
        describe "and mark it back as unread" do
          before do
            click_button "Marquer comme non lu"
            online_theory_2.reload
            user.reload
          end
          it { should have_button "Marquer comme lu" }
          it { should_not have_button "Marquer comme non lu" }
          specify { expect(user.theories.exists?(online_theory_2.id)).to eq(false) }
        end
      end
    end
    
    describe "visits offline theory" do
      before { visit chapter_path(chapter, :type => 1, :which => offline_theory.id) }
      it { should_not have_selector("h3", text: offline_theory.title) }
    end
    
    describe "tries to visit theory creation page" do
      before { visit new_chapter_theory_path(chapter) }
      it { should_not have_selector("h1", text: "Créer un point théorique") }
    end
    
    describe "tries to visit theory modification page" do
      before { visit edit_theory_path(online_theory) }
      it { should_not have_selector("h1", text: "Modifier un point théorique") }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "visits online theory" do
      before { visit chapter_path(chapter, :type => 1, :which => online_theory.id) }
      it { should have_selector("h3", text: online_theory.title) }
      it { should have_selector("a", text: "Modifier ce point théorique") }
      it { should have_selector("a", text: "Supprimer ce point théorique") }
      it { should have_selector("a", text: "point théorique") } # Link to add a new one
      
      specify { expect { click_link "Supprimer ce point théorique" }.to change(Theory, :count).by(-1) }
    end
    
    describe "visits offline theory" do
      before { visit chapter_path(chapter, :type => 1, :which => offline_theory.id) }
      it { should have_selector("h3", text: offline_theory.title) }
      it { should have_button("Mettre en ligne") }
      
      describe "and puts it online" do
        before do
          click_button "Mettre en ligne"
          offline_theory.reload
        end
        specify { expect(offline_theory.online).to eq(true) }
      end
    end
    
    describe "checks theory order" do
      before { visit chapter_path(chapter, :type => 1, :which => online_theory.id) }
      it { should have_link "bas" }
      it { should_not have_link "haut" } # Because position 1 out of >= 3
      
      describe "and modifies it" do
        before do
          click_link "bas"
          online_theory.reload
          online_theory_2.reload
        end
        specify { expect(online_theory.position).to eq(2) }
        specify { expect(online_theory_2.position).to eq(1) }
        it { should have_link "bas" } # Because position 2 out of >= 3
        it { should have_link "haut" }
        
        describe "and modifies it back" do
          before do
            click_link "haut"
            online_theory.reload
            online_theory_2.reload
          end
          specify do
            expect(online_theory.position).to eq(1)
            expect(online_theory_2.position).to eq(2)
          end
        end
      end
    end
    
    describe "visits theory creation page" do
      before { visit new_chapter_theory_path(empty_chapter) }
      it { should have_selector("h1", text: "Créer un point théorique") }
      
      describe "and sends with good information" do
        before do
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: newcontent
          click_button "Créer"
        end
        specify do
          expect(Theory.order(:id).last.title).to eq(newtitle)
          expect(Theory.order(:id).last.content).to eq(newcontent)
          expect(Theory.order(:id).last.position).to eq(1)
          expect(Theory.order(:id).last.online).to eq(false)
        end
        it { should have_selector("h3", text: newtitle) }
        it { should have_button("Mettre en ligne") }
        
        describe "and adds a second theory" do
          before do
            visit new_chapter_theory_path(empty_chapter)
            fill_in "Titre", with: newtitle2
            fill_in "MathInput", with: newcontent2
            click_button "Créer"
          end
          specify do
            expect(Theory.order(:id).last.title).to eq(newtitle2)
            expect(Theory.order(:id).last.content).to eq(newcontent2)
            expect(Theory.order(:id).last.position).to eq(2)
            expect(Theory.order(:id).last.online).to eq(false)
          end
          it { should have_selector("h3", text: newtitle2) }
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Titre", with: ""
          fill_in "MathInput", with: newcontent
          click_button "Créer"
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Créer un point théorique") }
        specify { expect(Theory.order(:id).last.content).to_not eq(newcontent) }
      end
    end
    
    describe "visits theory modification page" do
      before { visit edit_theory_path(online_theory) }
      it { should have_selector("h1", text: "Modifier un point théorique") }
      
      describe "and sends with good information" do
        before do
          fill_in "Titre", with: newtitle2
          fill_in "MathInput", with: newcontent2
          click_button "Modifier"
          online_theory.reload
        end
        specify do
          expect(online_theory.title).to eq(newtitle2)
          expect(online_theory.content).to eq(newcontent2)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Titre", with: newtitle2
          fill_in "MathInput", with: ""
          click_button "Modifier"
          online_theory.reload
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Modifier un point théorique") }
        specify { expect(online_theory.title).to_not eq(newtitle2) }
      end
    end
  end
end
