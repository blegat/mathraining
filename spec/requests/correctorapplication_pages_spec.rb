# -*- coding: utf-8 -*-
require "spec_helper"

describe "Correctorapplication pages", correctorapplication: true do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let(:user) { FactoryBot.create(:user, rating: 5000) }
  
  let(:new_application) { "Voici ma plus belle candidature !" }
  let(:new_answer) { "Et voici ma plus belle réponse !" }
  
  describe "user" do
    before { sign_in user }
    
    describe "visits new application path" do
      before { visit new_correctorapplication_path }
      it do
        should have_selector("h1", text: "Devenir correcteur")
        should have_content("vous pouvez postuler pour devenir correcteur")
        should have_button("Soumettre")
      end
        
      describe "and submits an application" do
        before do
          fill_in "MathInput", with: new_application
          click_button "Soumettre"
        end
        specify do
          expect(page).to have_success_message("Votre candidature a bien été envoyée.")
          expect(user.correctorapplications.last.content).to eq(new_application)
          expect(user.correctorapplications.last.processed).to eq(false)
        end
        
        describe "and root checks applications" do
          let!(:correctorapplication) { user.correctorapplications.last }
          before do
            sign_in root
            visit correctorapplications_path
          end
          it do
            should have_link("Candidatures (1)", href: correctorapplications_path) # In header
            should have_selector("h1", text: "Candidatures")
            should have_link("Voir", href: correctorapplication_path(correctorapplication))
          end
        end
        
        describe "and root checks this application" do
          let!(:correctorapplication) { user.correctorapplications.last }
          before do
            sign_in root
            visit correctorapplication_path(correctorapplication)
          end
          specify do
            expect(page).to have_content(new_application)
            expect(page).to have_button("Envoyer")
            expect(page).to have_link("Supprimer cette candidature")
            expect { click_link "Supprimer cette candidature" }.to change{user.correctorapplications.count}.by(-1)
          end
          
          describe "and answers to it" do
            before do
              old_discussion = Discussion.get_discussion_between(user, root)
              old_discussion.destroy if !old_discussion.nil?
              fill_in "MathInput", with: new_answer
              click_button "Envoyer"
              correctorapplication.reload
            end
            let!(:discussion) { Discussion.get_discussion_between(user, root) }
            specify do
              expect(page).to have_success_message("Votre réponse a bien été envoyée.")
              expect(correctorapplication.processed).to eq(true)
              expect(discussion).not_to eq(nil)
              expect(discussion.links.where(:user => user).first.nonread).to eq(2)
              expect(discussion.links.where(:user => root).first.nonread).to eq(0)
              expect(discussion.tchatmessages.order("created_at DESC").first.content).to eq(new_answer)
            end
          end
          
          describe "and answers to it with an empty message" do
            before do
              old_discussion = Discussion.get_discussion_between(user, root)
              old_discussion.destroy if !old_discussion.nil?
              fill_in "MathInput", with: ""
              click_button "Envoyer"
              correctorapplication.reload
            end
            let!(:discussion) { Discussion.get_discussion_between(user, root) }
            specify do
              expect(page).to have_error_message("Message doit être rempli")
              expect(correctorapplication.processed).to eq(false)
              expect(discussion).to eq(nil)
            end
          end
        end
      end
      
      describe "and sends an empty application" do
        before do
          fill_in "MathInput", with: ""
          click_button "Soumettre"
        end
        it { should have_error_message("Candidature doit être rempli") }
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
  end
end
