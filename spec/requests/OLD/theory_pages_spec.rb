# -*- coding: utf-8 -*-
require "spec_helper"

describe "Theory pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:empty_chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:online_theory) { FactoryGirl.create(:theory, chapter: chapter, online: true, position: 1) }
  let!(:online_theory2) { FactoryGirl.create(:theory, chapter: chapter, online: true, title: "Autre titre", content: "Autre contenu", position: 2) }
  let!(:offline_theory) { FactoryGirl.create(:theory, chapter: chapter, online: false, position: 3) }
  let(:newtitle) { "Mon nouveau titre de point théorique" }
  let(:newcontent) { "Mon nouveau point théorique" }
  let(:newtitle2) { "Mon nouveau titre de point théorique 2" }
  let(:newcontent2) { "Mon nouveau point théorique 2" }
  
  describe "visitor" do
    describe "visits online theory" do
      before { visit chapter_theory_path(chapter, online_theory) }
      it do
        should have_selector("h3", text: online_theory.title)
        should have_no_link("forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
      end
    end
    
    describe "visits offline theory" do
      before { visit chapter_theory_path(chapter, offline_theory) }
      it { should have_content(error_access_refused) }
    end
  end
  
  describe "user" do
    before { sign_in user }
    
    describe "visits online theory" do
      before { visit chapter_theory_path(chapter, online_theory2) }
      it do
        should have_selector("h3", text: online_theory2.title)
        should have_no_link("bas")
        should have_no_link("haut")
        should have_button("Marquer comme lu")
        should have_no_button("Marquer comme non lu")
        should have_link("forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
      end
      
      describe "and mark it as read" do
        before do
          click_button "Marquer comme lu"
          online_theory2.reload
          user.reload
        end
        specify do
          expect(page).to have_no_button("Marquer comme lu")
          expect(page).to have_button("Marquer comme non lu")
          expect(user.theories.exists?(online_theory2.id)).to eq(true)
        end
        
        describe "and mark it back as unread" do
          before do
            click_button "Marquer comme non lu"
            online_theory2.reload
            user.reload
          end
          specify do
            expect(page).to have_button "Marquer comme lu"
            expect(page).to have_no_button "Marquer comme non lu"
            expect(user.theories.exists?(online_theory2.id)).to eq(false)
          end
        end
      end
    end
    
    describe "visits online theory with wrong url" do
      before { visit chapter_theory_path(empty_chapter, online_theory) }
      it { should have_content(error_access_refused) }
    end
    
    describe "visits offline theory" do
      before { visit chapter_theory_path(chapter, offline_theory) }
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to visit theory creation page" do
      before { visit new_chapter_theory_path(chapter) }
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to visit theory modification page" do
      before { visit edit_theory_path(online_theory) }
      it { should have_content(error_access_refused) }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "visits online theory" do
      before { visit chapter_theory_path(chapter, online_theory) }
      specify do
        expect(page).to have_selector("h3", text: online_theory.title)
        expect(page).to have_selector("a", text: "Modifier ce point théorique")
        expect(page).to have_selector("a", text: "Supprimer ce point théorique")
        expect(page).to have_selector("a", text: "point théorique") # Link to add a new one
        expect { click_link "Supprimer ce point théorique" }.to change(Theory, :count).by(-1)
      end
    end
    
    describe "visits offline theory" do
      before { visit chapter_theory_path(chapter, offline_theory) }
      it do
        should have_selector("h3", text: offline_theory.title)
        should have_button("Mettre en ligne")
      end
      
      describe "and puts it online" do
        before do
          click_button "Mettre en ligne"
          offline_theory.reload
        end
        specify { expect(offline_theory.online).to eq(true) }
      end
    end
    
    describe "checks theory order" do
      before { visit chapter_theory_path(chapter, online_theory) }
      it do
        should have_link("bas")
        should have_no_link("haut") # Because position 1 out of >= 3
      end
      
      describe "and modifies it" do
        before do
          click_link "bas"
          online_theory.reload
          online_theory2.reload
        end
        specify do
          expect(online_theory.position).to eq(2)
          expect(online_theory2.position).to eq(1)
          expect(page).to have_link("bas") # Because position 2 out of >= 3
          expect(page).to have_link("haut")
        end
        
        describe "and modifies it back" do
          before do
            click_link "haut"
            online_theory.reload
            online_theory2.reload
          end
          specify do
            expect(online_theory.position).to eq(1)
            expect(online_theory2.position).to eq(2)
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
          expect(page).to have_selector("h3", text: newtitle)
          expect(page).to have_button("Mettre en ligne")
        end
        
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
            expect(page).to have_selector("h3", text: newtitle2)
          end
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Titre", with: ""
          fill_in "MathInput", with: newcontent
          click_button "Créer"
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Créer un point théorique")
          expect(Theory.order(:id).last.content).to_not eq(newcontent)
        end
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
        specify do
          expect(page).to have_content("erreur")
          expect(page).to have_selector("h1", text: "Modifier un point théorique")
          expect(online_theory.title).to_not eq(newtitle2)
        end
      end
    end
  end
end
