# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contestcorrection pages", contestcorrection: true do

  subject { page }
  
  let(:datetime_before) { DateTime.now - 2.hours }
  let(:datetime_before2) { DateTime.now - 1.hour }
  let(:datetime_after) { DateTime.now + 1.hour }
  let(:datetime_after2) { DateTime.now + 2.hours }

  let(:root) { FactoryBot.create(:root) }
  let(:user_participating) { FactoryBot.create(:advanced_user) }
  let(:user2_participating) { FactoryBot.create(:advanced_user) }
  let!(:user_organizer) { FactoryBot.create(:advanced_user) }
  
  let!(:contest) { FactoryBot.create(:contest, status: :in_progress) }
  let!(:contestsubject) { FactoryBot.create(:subject, contest: contest) }
  
  let!(:contestproblem_finished) { FactoryBot.create(:contestproblem, contest: contest, number: 1, start_time: datetime_before, end_time: datetime_before2, status: :in_correction) }
  
  let(:officialsol_finished) { contestproblem_finished.contestsolutions.where(:official => true).first }
  let!(:usersol_finished) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_finished, user: user_participating, corrected: false) }
  let!(:usersol2_finished) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_finished, user: user2_participating, corrected: true, score: 3) }
  
  let!(:newcorrection) { "Voici une correction spontanée." }
  let!(:newcorrection2) { "Voici une nouvelle correction." }
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
  before do
    contest.organizers << user_organizer
  end
  
  describe "organizer" do
    before { sign_in user_organizer }

    describe "visits a finished contestproblem page" do
      before { visit contestproblem_path(contestproblem_finished) }
      it do
        should have_selector("h1", text: "Problème ##{contestproblem_finished.number}")
        should have_no_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => officialsol_finished)) # We should not see it because it is non-public by default
        should have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => usersol_finished))
        should have_no_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => usersol2_finished)) # Already corrected
      end
    end
    
    describe "visits an official solution without having reserved" do
      before { visit contestproblem_path(contestproblem_finished, :sol => officialsol_finished) }
      it do
        should have_selector("h3", text: "Solution officielle (non-publique)")
        should have_link("Modifier la solution")
        should have_button("Enregistrer (non-publique)", disabled: true) # Not reserved so disabled
        should have_button("Enregistrer (publique)", disabled: true) # Not reserved so disabled
        should have_button("Enregistrer (publique étoilée)", disabled: true) # Not reserved so disabled
      end
    end
    
    describe "visits an official solution after having reserved" do
      before do
        officialsol_finished.update_attribute(:reservation, user_organizer.id)
        visit contestproblem_path(contestproblem_finished, :sol => officialsol_finished)
      end
      it do
        should have_content("Aucune solution étoilée")
        should have_link("Modifier la solution")
        should have_button("Enregistrer (non-publique)")
        should have_button("Enregistrer (publique)")
        should have_button("Enregistrer (publique étoilée)")
      end
      
      describe "and modifies it as a starred solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (publique étoilée)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify do
          expect(officialsol_finished.score).to eq(7)
          expect(officialsol_finished.star).to eq(true)
          expect(officialsol_finished.contestcorrection.content).to eq(newcorrection)
          expect(page).to have_no_content("Aucune solution étoilée")
          expect(page).to have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => officialsol_finished))
        end
      end
      
      describe "and modifies it as a bad solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (non-publique)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify do
          expect(officialsol_finished.score).to eq(0)
          expect(officialsol_finished.star).to eq(false)
          expect(officialsol_finished.contestcorrection.content).to eq(newcorrection)
        end
      end
      
      describe "and modifies it as a good non-starred solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (publique)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify do
          expect(officialsol_finished.score).to eq(7)
          expect(officialsol_finished.star).to eq(false)
          expect(officialsol_finished.contestcorrection.content).to eq(newcorrection)
        end
      end
    end
    
    describe "visits a user solution after having reserved" do
      before do
        usersol_finished.update_attribute(:reservation, user_organizer.id)
        visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
      end
      it do
        should have_selector("h3", text: "Solution de #{user_participating.name}")
        should have_content("- / 7")
        should have_link("Modifier la correction")
        should have_button("Enregistrer provisoirement")
        should have_button("Enregistrer")
        should have_button("Enregistrer et étoiler (si 7/7)")
      end
      
      describe "and marks it as wrong" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 2
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(usersol_finished.score).to eq(2)
          expect(usersol_finished.star).to eq(false)
          expect(usersol_finished.corrected).to eq(true)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
          expect(page).to have_no_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => usersol_finished)) # We should not see it anymore without javascript
          expect(page).to have_content("2 / 7")
        end
      end
      
      describe "and marks it as correct without star" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 7
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(usersol_finished.score).to eq(7)
          expect(usersol_finished.star).to eq(false)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
          expect(page).to have_content("7 / 7")
          expect(page).to have_content("Il faut au minimum une solution étoilée pour publier les résultats")
        end
      end
      
      describe "and marks it as correct with star" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 5 # Should be automatically set to 7
          click_button "Enregistrer et étoiler (si 7/7)"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(usersol_finished.score).to eq(7)
          expect(usersol_finished.star).to eq(true)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
          expect(page).to have_info_message("Le score a été mis automatiquement à 7/7 (car solution étoilée).")
          expect(page).to have_content("7 / 7")
          expect(page).to have_link("Publier les résultats")
        end
      end
      
      describe "and does a temporary correction" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 3
          click_button "Enregistrer provisoirement"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(usersol_finished.score).to eq(3)
          expect(usersol_finished.corrected).to eq(false)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
        end
        it { should have_content("3 / 7") }
      end
      
      describe "and writes an empty correction" do
        before do
          fill_in "MathInput", with: ""
          fill_in "score", with: 6
          click_button "Enregistrer et étoiler (si 7/7)"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(page).to have_error_message("Correction doit être rempli")
          expect(usersol_finished.score).to eq(-1)
          expect(usersol_finished.contestcorrection.content).to eq("-")
        end
      end

      describe "and hacked the system (he did not reserve)" do
        before do
          usersol_finished.update_attribute(:reservation, 0)
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 4
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(page).to have_error_message("Vous n'avez pas réservé.")
          expect(usersol_finished.score).to eq(-1)
          expect(usersol_finished.contestcorrection.content).to eq("-")
        end
      end
    end
        
    describe "after corrections" do
      before do
        usersol_finished.update(:score => 7,
                                :star => true,
                                :corrected => true)
        visit contestproblem_path(contestproblem_finished)
      end
      
      describe "publishes the results" do
        before do
          click_link "Publier les résultats"
          contestproblem_finished.reload
        end
        specify do
          expect(contestproblem_finished.corrected?).to eq(true)
          expect(contest.contestscores.count).to eq(2)
          expect(contest.contestscores.first.user).to eq(user_participating)
          expect(contest.contestscores.first.score).to eq(7)
          expect(contest.contestscores.first.rank).to eq(1)
          expect(contest.contestscores.first.undefined_medal?).to eq(true)
          expect(contest.contestscores.second.user).to eq(user2_participating)
          expect(contest.contestscores.second.score).to eq(3)
          expect(contest.contestscores.second.rank).to eq(2)
          expect(contest.contestscores.second.undefined_medal?).to eq(true)
          expect(contestsubject.messages.count).to eq(1)
          expect(contestsubject.messages.first.user_id).to eq(0)
        end
        
        describe "and visits a solution when recorrections are allowed" do
          before do
            contestproblem_finished.in_recorrection!
            usersol2_finished.update_attribute(:reservation, user_organizer.id)
            visit contestproblem_path(contestproblem_finished, :sol => usersol2_finished)
          end
          it do
            should have_selector("h3", text: "Solution de #{user2_participating.name}")
            should have_content("3 / 7")
            should have_link("Modifier la correction")
            should have_no_button("Enregistrer provisoirement") # does not appear in recorrection
            should have_button("Enregistrer")
            should have_button("Enregistrer et étoiler (si 7/7)")
          end
          
          describe "and modifies the score" do
            before do
              fill_in "MathInput", with: newcorrection
              fill_in "score", with: 7
              click_button "Enregistrer"
              usersol2_finished.reload
              usersol2_finished.contestcorrection.reload
              contest.reload
            end
            specify do
              expect(usersol2_finished.score).to eq(7)
              expect(usersol2_finished.star).to eq(false)
              expect(usersol2_finished.contestcorrection.content).to eq(newcorrection)
              expect(page).to have_content("7 / 7")
              # Contest scores should be updated:
              expect(contest.contestscores.count).to eq(2)
              expect(contest.contestscores.first.user).to eq(user_participating)
              expect(contest.contestscores.first.score).to eq(7)
              expect(contest.contestscores.first.rank).to eq(1)
              expect(contest.contestscores.first.undefined_medal?).to eq(true)
              expect(contest.contestscores.second.user).to eq(user2_participating)
              expect(contest.contestscores.second.score).to eq(7)
              expect(contest.contestscores.second.rank).to eq(1)
              expect(contest.contestscores.second.undefined_medal?).to eq(true)
            end
          end
        end
      end
    end
    
    # -- TESTS THAT REQUIRE JAVASCRIPT --
    
    describe "wants to modify the correction", :js => true do
      before do
        visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
        wait_for_js_imports
        click_link("Modifier la correction")
        wait_for_ajax
      end
      it do
        should have_content("Cliquez ici pour réserver.")
        should have_button("button-reserve")
        should have_button("Enregistrer provisoirement", disabled: true)
        should have_button("Enregistrer", disabled: true)
        should have_button("Enregistrer et étoiler (si 7/7)", disabled: true)
      end
      
      describe "and does not want anymore" do
        before do
          wait_for_js_imports
          click_button "Annuler"
          wait_for_ajax
        end
        specify { expect(page.evaluate_script("$('#form').height()")).to eq(0) } # Form should have disappeared
      end
      
      describe "and reserves it while somebody else reserved it" do
        before do
          usersol_finished.update_attribute(:reservation, root.id)
          wait_for_js_imports
          click_button "button-reserve"
          wait_for_ajax
          usersol_finished.reload
        end
        specify do
          expect(page).to have_content("Réservé par #{root.name}.")
          expect(usersol_finished.reservation).to eq(root.id)
        end
      end
      
      describe "and reserves it while corrections were published" do
        before do
          usersol_finished.update(:reservation => 0, :corrected => true, :score => 5)     
          contestproblem_finished.corrected!     
          wait_for_js_imports
          click_button "button-reserve"
          wait_for_ajax
          usersol_finished.reload
        end
        specify do
          expect(usersol_finished.reservation).to eq(0)
        end
      end
      
      describe "and reserves it" do
        before do
          wait_for_js_imports
          click_button "button-reserve"
          wait_for_ajax
          usersol_finished.reload
        end
        specify do
          expect(page).to have_content("Cliquez ici pour annuler votre réservation.")
          expect(page).to have_button("button-unreserve")
          expect(page).to have_button("Enregistrer provisoirement")
          expect(page).to have_button("Enregistrer")
          expect(page).to have_button("Enregistrer et étoiler (si 7/7)")
          expect(usersol_finished.reservation).to eq(user_organizer.id)
        end
      
        describe "and unreserves it" do
          before do
            wait_for_js_imports
            click_button "button-unreserve"
            wait_for_ajax
            usersol_finished.reload
          end
          specify do
            expect(page).to have_content("Cliquez ici pour réserver.")
            expect(page).to have_button("button-reserve")
            expect(page).to have_button("Enregistrer provisoirement", disabled: true)
            expect(page).to have_button("Enregistrer", disabled: true)
            expect(page).to have_button("Enregistrer et étoiler (si 7/7)", disabled: true)
            expect(usersol_finished.reservation).to eq(0)
          end
        end
      end
    end
    
    describe "modifies a solution by adding a file", :js => true do
      before do
        visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
        wait_for_js_imports
        click_link("Modifier la correction")
        wait_for_ajax
        click_button "button-reserve"
        wait_for_ajax
        fill_in "MathInput", with: newcorrection2
        fill_in "score", with: 6
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image1))
        click_button "BT2" # Name is 'Enregistrer' but capybara does not click on the right button, so we use the id instead...
        usersol_finished.reload
      end
      specify do
        expect(usersol_finished.contestcorrection.content).to eq(newcorrection2)
        expect(usersol_finished.score).to eq(6)
        expect(usersol_finished.corrected).to eq(true)
        expect(usersol_finished.contestcorrection.myfiles.count).to eq(1)
        expect(usersol_finished.contestcorrection.myfiles.first.file.filename.to_s).to eq(image1)
      end
    end
    
    describe "modifies a solution with a exe file", :js => true do
      before do
        visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
        wait_for_js_imports
        click_link("Modifier la correction")
        wait_for_ajax
        click_button "button-reserve"
        wait_for_ajax
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
        click_button "Enregistrer provisoirement"
        usersol_finished.reload
      end
      it do
        should have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
      end
    end
  end
end
