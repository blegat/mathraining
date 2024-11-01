# -*- coding: utf-8 -*-
require "spec_helper"

describe "Privacy policy pages", privacypolicy: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:user) { FactoryGirl.create(:user) }
  
  let(:newpolicy) { "Et ceci est la nouvelle politique !" }
  let(:newdescription) { "Et ceci la nouvelle description !" }
  
  describe "when no online policy" do
    
    describe "visitor" do      
      describe "visits root path" do
        before { visit root_path }
        it { should have_link("Confidentialité", href: last_privacypolicies_path) }
      end
      
      describe "tries to visit last policy" do
        before { visit last_privacypolicies_path }
        it { should have_error_message("Le site n'a actuellement aucune politique de confidentalité.") }
      end
    end
    
    describe "root" do
      before { sign_in root }
      
      describe "visits policy configuration page" do
        before { visit privacypolicies_path }
        it do
          should have_selector("h1", text: "Politiques de confidentialité")
          should have_button("Créer une nouvelle version")
        end
        
        describe "and adds a new one" do
          before { click_button("Créer une nouvelle version") }
          specify do
            expect(Privacypolicy.last.content).to eq("- À écrire -")
            expect(Privacypolicy.last.description).to eq("- À écrire -")
            expect(Privacypolicy.last.online).to eq(false)
          end
        end
      end
    end
  end
  
  describe "when one policy" do
    let!(:policy1) { FactoryGirl.create(:privacypolicy, online: true, publication_time: DateTime.now - 2.weeks) }
    let!(:policy2) { FactoryGirl.create(:privacypolicy, online: true, publication_time: DateTime.now - 1.week) }
    let!(:policy3_offline) { FactoryGirl.create(:privacypolicy, online: false, publication_time: DateTime.now) }
    before { user.update(:consent_time => DateTime.now - 10.days, :last_policy_read => false) }
    
    describe "user" do
      before { sign_in user }
      
      describe "visits any page" do
        before { visit subjects_path }
        it do
          should have_selector("h1", text: "Nouvelle politique de confidentialité")
          should have_no_content(policy1.description) # Because already accepted
          should have_content(policy2.description)
          should have_no_content(policy3_offline.description) # Because not published yet
          should have_button("Continuer sur Mathraining") # NB: not disabled in test environment
        end
        
        describe "and clicks without accepting" do # should not be possible in production mode
          before do
            click_button "Continuer sur Mathraining"
            user.reload
          end
          specify do
            expect(page).to have_error_message("Vous devez accepter notre politique de confidentialité pour pouvoir continuer sur le site.")
            expect(user.last_policy_read).to eq(false)
          end
        end
        
        describe "and accepts new policy" do
          before do
            check "consent1"
            check "consent2"
            click_button "Continuer sur Mathraining"
            user.reload
          end
          specify do
            expect(user.last_policy_read).to eq(true)
            expect(user.consent_time).to be >= policy2.publication_time
          end
        end
      end
      
      describe "visits last policy" do
        before { visit last_privacypolicies_path }
        it do
          should have_selector("h1", text: "Politique de confidentialité")
          should have_content(policy2.content)
          should have_link(href: privacypolicy_path(policy1))
          should have_no_link(href: privacypolicy_path(policy3_offline))
        end
      end
      
      describe "visits outdated policy" do
        before { visit privacypolicy_path(policy1) }
        it do
          should have_selector("h1", text: "Politique de confidentialité")
          should have_content(policy1.content)
          should have_link(href: privacypolicy_path(policy2))
        end
      end
    end
    
    describe "root" do
      before { sign_in root }
      
      describe "visits last policy" do
        before { visit last_privacypolicies_path }
        it do
          should have_selector("h1", text: "Politique de confidentialité")
          should have_content(policy2.content)
          should have_link(href: privacypolicy_path(policy1))
          should have_no_link(href: privacypolicy_path(policy3_offline))
          should have_link("Mettre à jour la politique de confidentialité", href: privacypolicies_path)
        end
      end
      
      describe "visits policy configuration page" do
        before { visit privacypolicies_path }
        it do
          should have_selector("h1", text: "Politiques de confidentialité")
          
          should have_link("Voir", href: privacypolicy_path(policy1))
          should have_content(policy1.description)
          should have_link("Modifier", href: edit_description_privacypolicy_path(policy1))
          
          should have_link("Voir", href: privacypolicy_path(policy2))
          should have_content(policy2.description)
          should have_link("Modifier", href: edit_description_privacypolicy_path(policy2))
          
          should have_link("Modifier", href: edit_privacypolicy_path(policy3_offline))
          should have_content(policy3_offline.description)
          should have_link("Modifier", href: edit_description_privacypolicy_path(policy3_offline))
          should have_link("Supprimer", href: privacypolicy_path(policy3_offline))
          should have_link("Publier", href: put_online_privacypolicy_path(policy3_offline))
          
          should have_no_button("Créer une nouvelle version") # Because there is already an offline one
        end
        
        specify do
          expect { click_link("Supprimer", href: privacypolicy_path(policy3_offline)) }.to change(Privacypolicy, :count).by(-1)
          expect { click_button "Créer une nouvelle version" }.to change(Privacypolicy, :count).by(1)
        end
        
        describe "and puts the new one online" do
          before do
            click_link("Publier")
            policy3_offline.reload
            root.reload
          end
          specify do
            expect(policy3_offline.online).to eq(true)
            expect(policy3_offline.publication_time).to be >= (DateTime.now - 10.minutes)
            expect(root.last_policy_read).to eq(false)
          end
          
          describe "and visits any page" do
            before { visit root_path }
            it do
              should have_selector("h1", text: "Nouvelle politique de confidentialité")
              should have_content(policy3_offline.description)
            end
          end
        end
      end
      
      describe "visits policy edit page" do
        before { visit edit_privacypolicy_path(policy3_offline) }
        it { should have_selector("h1", text: "Politiques de confidentialité > Modifier") }
        
        describe "and edits it" do
          before do
            fill_in "MathInput", with: newpolicy
            click_button "Modifier"
            policy3_offline.reload
          end
          specify do
            expect(page).to have_success_message("Modification enregistrée.")
            expect(policy3_offline.content).to eq(newpolicy)
          end
        end
        
        describe "and edits it with empty string" do
          before do
            fill_in "MathInput", with: ""
            click_button "Modifier"
            policy3_offline.reload
          end
          specify do
            expect(page).to have_selector("h1", text: "Politiques de confidentialité > Modifier")
            expect(page).to have_error_message("Contenu doit être rempli")
            expect(policy3_offline.content).not_to eq("")
          end
        end
      end
      
      describe "visits policy edit description page" do
        before { visit edit_description_privacypolicy_path(policy3_offline) }
        it { should have_selector("h1", text: "Politiques de confidentialité > Modifier la description") }
        
        describe "and edits it" do
          before do
            fill_in "MathInput", with: newdescription
            click_button "Modifier"
            policy3_offline.reload
          end
          specify do
            expect(page).to have_success_message("Modification enregistrée.")
            expect(policy3_offline.description).to eq(newdescription)
          end
        end
        
        describe "and edits it with empty string" do
          before do
            fill_in "MathInput", with: ""
            click_button "Modifier"
            policy3_offline.reload
          end
          specify do
            expect(page).to have_selector("h1", text: "Politiques de confidentialité > Modifier")
            expect(page).to have_error_message("Modifications doit être rempli")
            expect(policy3_offline.description).not_to eq("")
          end
        end
      end
    end
  end
end
