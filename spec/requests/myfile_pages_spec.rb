# -*- coding: utf-8 -*-
require "spec_helper"

describe "Myfile pages", myfile: true do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let(:user) { FactoryBot.create(:advanced_user) }
  
  let(:sub) { FactoryBot.create(:subject) } # Don't use name "subject" because it is used for the page
  let(:message) { FactoryBot.create(:message, subject: sub) }
  
  let(:problem) { FactoryBot.create(:problem, online: true) }
  let(:submission) { FactoryBot.create(:submission, problem: problem, status: :correct) }
  let(:correction) { FactoryBot.create(:correction, submission: submission) }
  
  let(:contest) { FactoryBot.create(:contest) }
  let(:contestproblem) { FactoryBot.create(:contestproblem, contest: contest) }
  let(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem) }
  let(:contestcorrection) { contestsolution.contestcorrection }
  
  let(:discussion) { create_discussion_between(root, user, "Bonjour", "Salut") }
  let(:tchatmessage) { discussion.tchatmessages.first }
  
  let(:messagemyfile) { FactoryBot.create(:messagemyfile, myfiletable: message) }
  let(:submissionmyfile) { FactoryBot.create(:submissionmyfile, myfiletable: submission) }
  let(:correctionmyfile) { FactoryBot.create(:correctionmyfile, myfiletable: correction) }
  let(:contestsolutionmyfile) { FactoryBot.create(:contestsolutionmyfile, myfiletable: contestsolution) }
  let(:contestcorrectionmyfile) { FactoryBot.create(:contestcorrectionmyfile, myfiletable: contestcorrection) }
  let(:tchatmessagemyfile) { FactoryBot.create(:tchatmessagemyfile, myfiletable: tchatmessage) }

  describe "root" do
    before { sign_in root }
    
    describe "visits all files page" do
      let!(:messagemyfile) { FactoryBot.create(:messagemyfile, myfiletable: message) } # Force its creation
      before { visit myfiles_path }
      it do
        should have_selector("h1", text: "Pièces jointes")
        should have_link("Voir", href: myfile_path(messagemyfile))
        should have_link(href: rails_blob_url(messagemyfile.file, :only_path => true, :disposition => 'attachment'))
      end
    end
    
    describe "visits one message file" do
      before { visit myfile_path(messagemyfile) }
      it do
        should have_current_path(subject_path(sub, :page => 1, :msg => message))
        should have_link(messagemyfile.file.filename.to_s, href: rails_blob_url(messagemyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: fake_delete_myfile_path(messagemyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: fake_delete_myfile_path(messagemyfile)) }
        it do
          should have_current_path(subject_path(sub, :page => 1, :msg => message, :q => "all"))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one submission file" do
      before { visit myfile_path(submissionmyfile) }
      it do
        should have_current_path(problem_submission_path(problem, submission))
        should have_link(submissionmyfile.file.filename.to_s, href: rails_blob_url(submissionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: fake_delete_myfile_path(submissionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: fake_delete_myfile_path(submissionmyfile)) }
        it do
          should have_current_path(problem_submission_path(problem, submission))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one correction file" do
      before { visit myfile_path(correctionmyfile) }
      it do
        should have_current_path(problem_submission_path(problem, submission))
        should have_link(correctionmyfile.file.filename.to_s, href: rails_blob_url(correctionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: fake_delete_myfile_path(correctionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: fake_delete_myfile_path(correctionmyfile)) }
        it do
          should have_current_path(problem_submission_path(problem, submission))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one contestsolution file" do
      before { visit myfile_path(contestsolutionmyfile) }
      it do
        should have_current_path(contestproblem_contestsolution_path(contestproblem, contestsolution))
        should have_link(contestsolutionmyfile.file.filename.to_s, href: rails_blob_url(contestsolutionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: fake_delete_myfile_path(contestsolutionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: fake_delete_myfile_path(contestsolutionmyfile)) }
        it do
          should have_current_path(contestproblem_contestsolution_path(contestproblem, contestsolution))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one contestcorrection file" do
      before { visit myfile_path(contestcorrectionmyfile) }
      it do
        should have_current_path(contestproblem_contestsolution_path(contestproblem, contestsolution))
        should have_link(contestcorrectionmyfile.file.filename.to_s, href: rails_blob_url(contestcorrectionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: fake_delete_myfile_path(contestcorrectionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: fake_delete_myfile_path(contestcorrectionmyfile)) }
        it do
          should have_current_path(contestproblem_contestsolution_path(contestproblem, contestsolution))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one tchatmessage file" do
      before { visit myfile_path(tchatmessagemyfile) }
      it { should have_current_path(myfiles_path) }
    end
    
    describe "visits one tchatmessage file manually" do
      let!(:tchatmessagemyfile) { FactoryBot.create(:tchatmessagemyfile, myfiletable: tchatmessage) } # Force its creation
      before { visit discussion_path(discussion) }
      it do
        should have_link(tchatmessagemyfile.file.filename.to_s, href: rails_blob_url(tchatmessagemyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: fake_delete_myfile_path(tchatmessagemyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: fake_delete_myfile_path(tchatmessagemyfile)) }
        it do
          should have_current_path(myfiles_path)
          should have_success_message("Contenu de la pièce jointe supprimé.")
        end
      end
    end
  end
end
