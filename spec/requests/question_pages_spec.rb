# -*- coding: utf-8 -*-
require "spec_helper"

describe "Question pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:empty_chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:online_exercise) { FactoryGirl.create(:exercise, chapter: chapter, online: true, position: 1) }
  let!(:online_qcm) { FactoryGirl.create(:qcm, chapter: chapter, online: true, position: 2) }
  let!(:online_item_correct) { FactoryGirl.create(:item_correct, question: online_qcm, position: 1) }
  let!(:online_item_incorrect) { FactoryGirl.create(:item, question: online_qcm, position: 2) }
  let!(:offline_exercise) { FactoryGirl.create(:exercise_decimal, chapter: chapter, online: false, position: 3) }
  let!(:offline_qcm) { FactoryGirl.create(:qcm_multiple, chapter: chapter, online: false, position: 4) }
  let!(:offline_item_correct) { FactoryGirl.create(:item_correct, question: offline_qcm, position: 1) }
  let!(:offline_item_incorrect) { FactoryGirl.create(:item, question: offline_qcm, position: 2) }
  let!(:offline_item_correct2) { FactoryGirl.create(:item_correct, question: offline_qcm, position: 3) }
  let!(:empty_qcm) { FactoryGirl.create(:qcm, chapter: chapter, online: false, position: 5) }
  
  let(:newstatement) { "Combien vaut 3+3.5 ?" }
  let(:newanswer) { 6.5 }
  let(:newdecimal) { true }
  let(:newlevel) { 3 }
  
  let(:newstatement2) { "Combien vaut 1+2 ?" }
  let(:newanswer2) { 3 }
  let(:newdecimal2) { false }
  let(:newlevel2) { 4 }
  
  let(:newstatement3) { "Lesquelles sont vraies ?" }
  let(:newmanyanswers3) { true }
  let(:newlevel3) { 2 }
  
  let(:newitem) { "Nouveau choix" }
  let(:newitem2) { "Nouveau choix 2" }
  let(:newitem3) { "Nouveau choix 3" }
  
  let(:newexplanation) { "Nouvelle explication" }
  
  describe "visitor" do
    describe "visits online exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => online_exercise.id) }
      it { should have_selector("div", text: online_exercise.statement) }
    end
    
    describe "visits offline exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => offline_exercise.id) }
      it { should_not have_selector("div", text: offline_exercise.statement) }
    end
  end
  
  describe "user" do
    before { sign_in user }
    
    describe "visits online exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => online_exercise.id) }
      it { should have_selector("div", text: online_exercise.statement) }
      
      # Do some stuff with exercise
    end
    
    describe "visits offline exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => offline_exercise.id) }
      it { should_not have_selector("div", text: offline_exercise.statement) }
    end
    
    describe "tries to visit exercise creation page" do
      before { visit new_chapter_question_path(chapter) }
      it { should_not have_selector("h1", text: "Créer un exercice") }
    end
    
    describe "tries to visit exercise modification page" do
      before { visit edit_question_path(online_exercise) }
      it { should_not have_selector("h1", text: "Modifier un exercice") }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "visits online exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => online_exercise.id) }
      it { should have_selector("div", text: online_exercise.statement) }
      it { should_not have_selector("a", text: "Supprimer cet exercice") }
      it { should have_selector("a", text: "Modifier l'explication") }
    end
    
    describe "visits offline exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => offline_exercise.id) }
      it { should have_selector("div", text: offline_exercise.statement) }
      it { should have_selector("a", text: "Modifier cet exercice") }
      it { should have_selector("a", text: "Supprimer cet exercice") }
      it { should have_selector("a", text: "QCM") } # Link to add a new QCM
      it { should have_button("Mettre en ligne") }
      
      specify { expect { click_link "Supprimer cet exercice" }.to change(Question, :count).by(-1) }
      
      describe "and puts it online" do
        before do
          click_button "Mettre en ligne"
          offline_exercise.reload
        end
        specify { expect(offline_exercise.online).to eq(true) }
      end
    end
    
    describe "visits explanation page" do
      before { visit question_explanation_path(online_exercise) }
      it { should have_selector("h1", text: "Explication") }
      
      describe "and modifies it" do
        before do
          fill_in "MathInput", with: newexplanation
          click_button "Modifier"
          online_exercise.reload
        end
        specify { expect(online_exercise.explanation).to eq(newexplanation) }
      end
    end
    
    describe "checks question order" do
      before { visit chapter_path(chapter, :type => 5, :which => online_exercise.id) }
      it { should have_link "bas" }
      it { should_not have_link "haut" } # Because position 1 out of >= 4
      
      describe "and modifies it" do
        before do
          click_link "bas"
          online_exercise.reload
          online_qcm.reload
        end
        specify { expect(online_exercise.position).to eq(2) }
        specify { expect(online_qcm.position).to eq(1) }
        it { should have_link "bas" } # Because position 2 out of >= 4
        it { should have_link "haut" }
        
        describe "and modifies it back" do
          before do
            click_link "haut"
            online_exercise.reload
            online_qcm.reload
          end
          specify do
            expect(online_exercise.position).to eq(1)
            expect(online_qcm.position).to eq(2)
          end
        end
      end
    end
    
    describe "visits exercise creation page" do
      before { visit new_chapter_question_path(empty_chapter) }
      it { should have_selector("h1", text: "Créer un exercice") }
      
      describe "and sends with good information" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Réponse", with: newanswer
          if newdecimal
            check "Cochez si la réponse est décimale"
          end
          fill_in "Niveau", with: newlevel
          click_button "Créer"
        end
        specify do
          expect(Question.order(:id).last.statement).to eq(newstatement)
          expect(Question.order(:id).last.answer).to eq(newanswer)
          expect(Question.order(:id).last.decimal).to eq(newdecimal)
          expect(Question.order(:id).last.level).to eq(newlevel)
          expect(Question.order(:id).last.is_qcm).to eq(false)
          expect(Question.order(:id).last.position).to eq(1)
          expect(Question.order(:id).last.online).to eq(false)
        end
        it { should have_selector("div", text: newstatement) }
        it { should have_button("Mettre en ligne") }
        
        describe "and adds a second exercise" do
          before do
            visit new_chapter_question_path(empty_chapter)
            fill_in "MathInput", with: newstatement2
            fill_in "Réponse", with: newanswer2
            if newdecimal2
              check "Cochez si la réponse est décimale"
            end
            fill_in "Niveau", with: newlevel2
            click_button "Créer"
          end
          specify do
            expect(Question.order(:id).last.statement).to eq(newstatement2)
            expect(Question.order(:id).last.answer).to eq(newanswer2)
            expect(Question.order(:id).last.decimal).to eq(newdecimal2)
            expect(Question.order(:id).last.level).to eq(newlevel2)
            expect(Question.order(:id).last.is_qcm).to eq(false)
            expect(Question.order(:id).last.position).to eq(2)
            expect(Question.order(:id).last.online).to eq(false)
          end
          it { should have_selector("div", text: newstatement2) }
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "MathInput", with: ""
          fill_in "Réponse", with: newanswer
          fill_in "Niveau", with: newlevel
          click_button "Créer"
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Créer un exercice") }
        specify { expect(Question.order(:id).last.answer).to_not eq(newanswer) }
      end
    end
    
    describe "visits exercise modification page" do
      before { visit edit_question_path(offline_exercise) }
      it { should have_selector("h1", text: "Modifier un exercice") }
      
      describe "and sends with good information" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Réponse", with: newanswer
          if newdecimal
            check "Cochez si la réponse est décimale"
          end
          fill_in "Niveau", with: newlevel
          click_button "Modifier"
          offline_exercise.reload
        end
        specify do
          expect(offline_exercise.statement).to eq(newstatement)
          expect(offline_exercise.answer).to eq(newanswer)
          expect(offline_exercise.decimal).to eq(newdecimal)
          expect(offline_exercise.level).to eq(newlevel)
          expect(offline_exercise.is_qcm).to eq(false)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "MathInput", with: ""
          fill_in "Réponse", with: newanswer
          fill_in "Niveau", with: newlevel
          click_button "Modifier"
          offline_exercise.reload
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Modifier un exercice") }
        specify { expect(offline_exercise.answer).to_not eq(newanswer) }
      end
    end
    
    describe "visits qcm creation page" do
      before { visit new_chapter_question_path(empty_chapter, :qcm => 1) }
      it { should have_selector("h1", text: "Créer un exercice") }
      
      describe "and sends with good information" do
        before do
          fill_in "MathInput", with: newstatement3
          check "Cochez si plusieurs réponses sont possibles"
          fill_in "Niveau", with: newlevel3
          click_button "Créer"
        end
        specify do
          expect(Question.order(:id).last.statement).to eq(newstatement3)
          expect(Question.order(:id).last.many_answers).to eq(true)
          expect(Question.order(:id).last.level).to eq(newlevel3)
          expect(Question.order(:id).last.is_qcm).to eq(true)
          expect(Question.order(:id).last.online).to eq(false)
        end
        it { should have_selector("h1", text: "Choix") }
      end
    end
    
    describe "visits qcm modification page" do
      before { visit edit_question_path(offline_qcm) }
      it { should have_selector("h1", text: "Modifier un exercice") }
      
      describe "and sends with good information" do
        before do
          fill_in "MathInput", with: newstatement3
          uncheck "Cochez si plusieurs réponses sont possibles"
          fill_in "Niveau", with: newlevel3
          click_button "Modifier"
          offline_qcm.reload
          offline_item_correct2.reload
        end
        specify do
          expect(offline_qcm.statement).to eq(newstatement3)
          expect(offline_qcm.many_answers).to eq(false)
          expect(offline_qcm.level).to eq(newlevel3)
          expect(offline_qcm.is_qcm).to eq(true)
          expect(offline_item_correct2.ok).to eq(false) # Qcm modified from many answer to single answer so second correct is set to incorrect
        end
      end
    end
    
    describe "visits choices modification page" do
      before { visit question_manage_items_path(offline_qcm) }
      it { should have_selector("h1", text: "Choix") }
      
      it { should have_link("update_item_incorrect_" + offline_item_correct.id.to_s) }
      it { should_not have_link("update_item_correct_" + offline_item_correct.id.to_s) }
      it { should_not have_link("update_item_up_" + offline_item_correct.id.to_s) }
      it { should have_link("update_item_down_" + offline_item_correct.id.to_s) }
      
      it { should_not have_link("update_item_incorrect_" + offline_item_incorrect.id.to_s) }
      it { should have_link("update_item_correct_" + offline_item_incorrect.id.to_s) }
      it { should have_link("update_item_up_" + offline_item_incorrect.id.to_s) }
      it { should have_link("update_item_down_" + offline_item_incorrect.id.to_s) }
     
      it { should have_link("update_item_incorrect_" + offline_item_correct2.id.to_s) }
      it { should_not have_link("update_item_correct_" + offline_item_correct2.id.to_s) }
      it { should have_link("update_item_up_" + offline_item_correct2.id.to_s) }
      it { should_not have_link("update_item_down_" + offline_item_correct2.id.to_s) }
      
      describe "and adds a new choice" do
        before do
          fill_in "create_item_field", with: newitem
          check "create_item_value"
          click_button "create_item_button"
        end
        specify do
          expect(offline_qcm.items.order(:id).last.ans).to eq(newitem)
          expect(offline_qcm.items.order(:id).last.ok).to eq(true)
          expect(offline_qcm.items.order(:id).last.position).to eq(4)
        end
      end
      
      describe "and udpates a choice value" do
        before do
          fill_in ("update_item_field_" + offline_item_correct.id.to_s), with: newitem
          click_button ("update_item_button_" + offline_item_correct.id.to_s)
          offline_item_correct.reload
        end
        specify { expect(offline_item_correct.ans).to eq(newitem) }
      end
      
      describe "and make a correct choice incorrect" do
        before do
          click_link "update_item_incorrect_" + offline_item_correct.id.to_s
          offline_item_correct.reload
        end
        specify { expect(offline_item_correct.ok).to eq(false) }
      end
      
      describe "and make a incorrect choice correct" do
        before do
          click_link "update_item_correct_" + offline_item_incorrect.id.to_s
          offline_item_incorrect.reload
        end
        specify { expect(offline_item_correct.ok).to eq(true) }
      end
      
      describe "deletes a choice" do
        specify { expect { click_link("update_item_delete_" + offline_item_correct.id.to_s) }.to change(Item, :count).by(-1) }
      end
      
      describe "and moves a choice down" do
        before do
          click_link "update_item_down_" + offline_item_correct.id.to_s
          offline_item_correct.reload
          offline_item_incorrect.reload
        end
        specify do
          expect(offline_item_correct.position).to eq(2)
          expect(offline_item_incorrect.position).to eq(1)
        end
      end
      
      describe "and moves a choice up" do
        before do
          click_link "update_item_up_" + offline_item_incorrect.id.to_s
          offline_item_correct.reload
          offline_item_incorrect.reload
        end
        specify do
          expect(offline_item_correct.position).to eq(2)
          expect(offline_item_incorrect.position).to eq(1)
        end
      end
    end
    
    describe "visits choices of empty qcm" do
      before { visit question_manage_items_path(empty_qcm) }
      it { should have_selector("h1", text: "Choix") }
      
      describe "and adds an incorrect choice" do
        before do
          fill_in "create_item_field", with: newitem
          click_button "create_item_button"
        end
        specify do
          expect(empty_qcm.items.where(:position => 1).first.ans).to eq(newitem)
          expect(empty_qcm.items.where(:position => 1).first.ok).to eq(true) # Automatically set to true because only one choice
        end
        
        describe "and adds a correct choice" do
          before do
            fill_in "create_item_field", with: newitem2
            check "create_item_value"
            click_button "create_item_button"
          end
          specify do
            expect(empty_qcm.items.where(:position => 2).first.ans).to eq(newitem2)
            expect(empty_qcm.items.where(:position => 2).first.ok).to eq(true)
            expect(empty_qcm.items.where(:position => 1).first.ok).to eq(false) # Automatically set to false because new choice is set to true
          end
          
          describe "and modifies the correctness" do
            before { click_link ("update_item_correct_" + empty_qcm.items.where(:position => 1).first.id.to_s) }
            specify do
              expect(empty_qcm.items.where(:position => 1).first.ok).to eq(true)
              expect(empty_qcm.items.where(:position => 2).first.ok).to eq(false) # Automatically set to false because choice 1 is set to true
            end
            
            describe "and deletes the correct choice" do
              before { click_link ("update_item_delete_" + empty_qcm.items.where(:position => 1).first.id.to_s) }
              specify do
                expect(empty_qcm.items.count).to eq(1)
                expect(empty_qcm.items.first.ans).to eq(newitem2)
                expect(empty_qcm.items.first.ok).to eq(true)
              end
            end
          end
        end
      end
    end
  end
end
