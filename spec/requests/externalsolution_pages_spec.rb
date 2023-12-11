# -*- coding: utf-8 -*-
require "spec_helper"

describe "External solution pages", externalsolution: true do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let!(:problem) { FactoryGirl.create(:problem) }
  let!(:externalsolution) { FactoryGirl.create(:externalsolution, problem: problem) }
  let!(:extract) { FactoryGirl.create(:extract, externalsolution: externalsolution) }
  let(:newurl) { "https://www.mathraining.be" }
  let(:newtext) { "Nouveau petit extrait" }

  describe "admin" do
    before do
      sign_in admin
      visit problem_manage_externalsolutions_path(problem)
    end
    
    it { should have_selector("h1", text: "Solutions externes") }
    
    describe "creates an external solution" do
      describe "with good information" do
        before do
          find_by_id('create_externalsolution_field').set(newurl)
          find_by_id('create_externalsolution_button').click
        end
        specify do
          expect(page).to have_success_message("Solution externe enregistrée")
          expect(problem.externalsolutions.order(:id).last.url).to eq(newurl)
        end
      end
      
      describe "with wrong information" do
        before do
          find_by_id('create_externalsolution_field').set("")
          find_by_id('create_externalsolution_button').click
        end
        specify do
          expect(page).to have_error_message("URL doit être rempli")
          expect(problem.externalsolutions.order(:id).last.url).to_not eq(newurl)
        end
      end
    end
    
    describe "edits an external solution" do
      describe "with good information" do
        before do
          find_by_id('update_externalsolution_field_' + externalsolution.id.to_s).set(newurl)
          find_by_id('update_externalsolution_button_' + externalsolution.id.to_s).click
          externalsolution.reload
        end
        specify do
          expect(page).to have_success_message("Solution externe modifiée")
          expect(externalsolution.url).to eq(newurl)
        end
      end
      
      describe "with wrong information" do
        before do
          find_by_id('update_externalsolution_field_' + externalsolution.id.to_s).set("")
          find_by_id('update_externalsolution_button_' + externalsolution.id.to_s).click
          externalsolution.reload
        end
        specify do
          expect(page).to have_error_message("URL doit être rempli")
          expect(externalsolution.url).to_not eq(newurl)
        end
      end
    end
    
    describe "deletes an external solution" do
      specify { expect { find_by_id('delete_externalsolution_' + externalsolution.id.to_s).click }.to change(problem.externalsolutions, :count).by(-1) }
    end
    
    describe "creates an extract" do
      describe "with good information" do
        let!(:submission_plagiarized) { FactoryGirl.create(:submission, problem: problem, status: :plagiarized, content: "Ma solution : " + newtext) }
        let!(:suspicion) { FactoryGirl.create(:suspicion, submission: submission_plagiarized, source: externalsolution.url, status: :confirmed) }
        before do
          find_by_id('create_extract_field_' + externalsolution.id.to_s).set(newtext)
          find_by_id('create_extract_button_' + externalsolution.id.to_s).click
        end
        specify do
          expect(page).to have_success_message("Extrait enregistré")
          expect(page).to have_content("Score : 1 / 1") # Because submission_plagiarized contains the extract newtext
          expect(externalsolution.extracts.order(:id).last.text).to eq(newtext)
        end
      end
      
      describe "with wrong information" do
        before do
          find_by_id('create_extract_field_' + externalsolution.id.to_s).set("")
          find_by_id('create_extract_button_' + externalsolution.id.to_s).click
        end
        specify do
          expect(page).to have_error_message("Extrait doit être rempli")
          expect(externalsolution.extracts.order(:id).last.text).to_not eq(newtext)
        end
      end
    end
    
    describe "edits an extract" do
      describe "with good information" do
        before do
          find_by_id('update_extract_field_' + extract.id.to_s).set(newtext)
          find_by_id('update_extract_button_' + extract.id.to_s).click
          extract.reload
        end
        specify do
          expect(page).to have_success_message("Extrait modifié")
          expect(extract.text).to eq(newtext)
        end
      end
      
      describe "with wrong information" do
        before do
          find_by_id('update_extract_field_' + extract.id.to_s).set("")
          find_by_id('update_extract_button_' + extract.id.to_s).click
          externalsolution.reload
        end
        specify do
          expect(page).to have_error_message("Extrait doit être rempli")
          expect(extract.text).to_not eq(newtext)
        end
      end
    end
    
    describe "deletes an extract" do
      specify { expect { find_by_id('delete_extract_' + extract.id.to_s).click }.to change(externalsolution.extracts, :count).by(-1) }
    end
  end
end
