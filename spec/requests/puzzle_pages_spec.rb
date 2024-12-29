# -*- coding: utf-8 -*-
require "spec_helper"

describe "Puzzle pages", puzzle: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:puzzle) { FactoryGirl.create(:puzzle, position: 1) }
  
  let(:newstatement) { "Voici une énigme très compliquée !" }
  let(:newcode) { "45AB2" }
  let(:newexplanation) { "C'était très difficile." }

  describe "root" do
    before do
      travel_to Puzzle.start_date - 1.day
      sign_in root
    end
    
    describe "visits puzzle index page" do
      before { visit puzzles_path }
      it do
        should have_selector("h1", text: "Énigmes")
        should have_content(puzzle.statement)
        should have_content(puzzle.code)
        should have_link("Modifier cette énigme", href: edit_puzzle_path(puzzle))
        should have_link("Supprimer cette énigme", href: puzzle_path(puzzle))
        should have_no_link("haut")
        should have_no_link("bas")
        should have_button("Créer une énigme")
      end
      
      specify { expect { click_link "Supprimer cette énigme" }.to change(Puzzle, :count).by(-1) }
    end
    
    describe "visits puzzle index page with more than one puzzle" do
      let!(:puzzle2) { FactoryGirl.create(:puzzle, position: 2) }
      before { visit puzzles_path }
      it do
        should have_link("bas", href: order_puzzle_path(puzzle, :new_position => 2))
        should have_no_link("haut", href: order_puzzle_path(puzzle))
        should have_no_link("bas", href: order_puzzle_path(puzzle2))
        should have_link("haut", href: order_puzzle_path(puzzle2, :new_position => 1))
      end
      
      describe "and move one puzzle down" do
        before do
          click_link("bas")
          puzzle.reload
          puzzle2.reload
        end
        specify do
          expect(page).to have_success_message("Énigme déplacée vers le bas")
          expect(puzzle.position).to eq(2)
          expect(puzzle2.position).to eq(1)
        end
      end
      
      describe "and move one puzzle up" do
        before do
          click_link("haut")
          puzzle.reload
          puzzle2.reload
        end
        specify do
          expect(page).to have_success_message("Énigme déplacée vers le haut")
          expect(puzzle.position).to eq(2)
          expect(puzzle2.position).to eq(1)
        end
      end
    end
    
    describe "visits puzzle edit page" do
      before { visit edit_puzzle_path(puzzle) }
      it do
        should have_selector("h1", text: "Modifier une énigme")
        should have_button("Modifier")
      end
      
      describe "and edits the puzzle" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Code", with: newcode
          fill_in "Explication", with: newexplanation
          click_button "Modifier"
          puzzle.reload
        end
      
        specify do
          expect(page).to have_selector("h1", text: "Énigmes")
          expect(page).to have_success_message("Énigme modifiée")
          expect(puzzle.statement).to eq(newstatement)
          expect(puzzle.code).to eq(newcode)
          expect(puzzle.explanation).to eq(newexplanation)
        end
      end
      
      describe "and edits the puzzle with wrong code" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Code", with: "FAUX"
          fill_in "Explication", with: newexplanation
          click_button "Modifier"
          puzzle.reload
        end
      
        specify do
          expect(page).to have_selector("h1", text: "Modifier une énigme")
          expect(page).to have_error_message("Le code doit contenir exactement 5 caractères")
          expect(puzzle.statement).not_to eq(newstatement)
          expect(puzzle.code).not_to eq(newcode)
          expect(puzzle.explanation).not_to eq(newexplanation)
        end
      end
    end
    
    describe "visits puzzle creation page" do
      before { visit new_puzzle_path }
      it do
        should have_selector("h1", text: "Créer une énigme")
        should have_button("Créer")
      end
      
      describe "and creates a puzzle" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Code", with: newcode
          fill_in "Explication", with: newexplanation
          click_button "Créer"
        end
      
        specify do
          expect(page).to have_selector("h1", text: "Énigmes")
          expect(page).to have_success_message("Énigme ajoutée")
          expect(Puzzle.order(:id).last.statement).to eq(newstatement)
          expect(Puzzle.order(:id).last.code).to eq(newcode)
          expect(Puzzle.order(:id).last.explanation).to eq(newexplanation)
        end
      end
      
      describe "and creates a puzzle with empty statement" do
        before do
          fill_in "MathInput", with: ""
          fill_in "Code", with: newcode
          click_button "Créer"
        end
      
        specify do
          expect(page).to have_selector("h1", text: "Créer une énigme")
          expect(page).to have_error_message("Énoncé doit être rempli")
          expect(Puzzle.order(:id).last.code).not_to eq(newcode)
        end
      end
    end
  end
  
  describe "user" do
    before do
      travel_to Puzzle.start_date + 1.minute
      sign_in user
    end
    
    describe "visits puzzle main page", :js => true do
      before do
        visit ten_years_path
        wait_for_ajax
      end
      it do
        should have_content("Pour célébrer")
        should have_content(puzzle.statement)
        should have_no_content(puzzle.code)
        should have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-none")
      end
      
      describe "and writes a code" do
        before do
          fill_in "code-#{puzzle.id}", with: "TEST1"
          wait_for_ajax
        end
        it { should have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-to-submit") }
        
        #describe "and erases the code" do
        #  before do
        #    fill_in "code-#{puzzle.id}", with: "" # Does not trigger the oninput the second time...
        #    wait_for_ajax
        #  end
        #  it { should have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-none") }
        #end
        
        describe "and submits the code" do
          before do
            click_button "submit-#{puzzle.id}"
            wait_for_ajax
          end
          specify do
            expect(Puzzleattempt.last.user).to eq(user)
            expect(Puzzleattempt.last.puzzle).to eq(puzzle)
            expect(Puzzleattempt.last.code).to eq("TEST1")
            expect(page).to have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-submitted") 
          end
        end
      end
      
      describe "and submits a wrong code" do
        before do
          fill_in "code-#{puzzle.id}", with: "TEST"
          click_button "submit-#{puzzle.id}"
          wait_for_ajax
        end
        specify do
          expect(Puzzleattempt.where(:puzzle => puzzle, :user => user).count).to eq(0)
          expect(page).to have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-error") 
        end
      end
    end
    
    describe "visits puzzle main page when a guess is already done", :js => true do
      let!(:puzzleattempt) { Puzzleattempt.create(:puzzle => puzzle, :user => user, :code => "HELLO") }
      before do
        visit ten_years_path
        wait_for_ajax
      end
      it do
        should have_content("Pour célébrer")
        should have_content(puzzle.statement)
        should have_no_content(puzzle.code)
        should have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-submitted")
      end
      
      describe "and writes another code" do
        before do
          fill_in "code-#{puzzle.id}", with: "TEST2"
          wait_for_ajax
        end
        it { should have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-to-submit") }
        
        #describe "and writes back the initial code" do
        #  before do
        #    fill_in "code-#{puzzle.id}", with: puzzleattempt.code # Does not trigger the oninput the second time...
        #    wait_for_ajax
        #  end
        #  it { should have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-none") }
        #end
        
        describe "and submits the code" do
          before do
            click_button "submit-#{puzzle.id}"
            wait_for_ajax
            puzzleattempt.reload
          end
          specify do
            expect(puzzleattempt.code).to eq("TEST2")
            expect(page).to have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-submitted") 
          end
        end
      end
      
      describe "and submits an empty code" do
        before do
          fill_in "code-#{puzzle.id}", with: ""
          click_button "submit-#{puzzle.id}"
          wait_for_ajax
        end
        specify do
          expect(Puzzleattempt.where(:puzzle => puzzle, :user => user).count).to eq(0)
          expect(page).to have_selector("div", id: "status-#{puzzle.id}", class: "puzzle-none") 
        end
      end
    end
  end
end
