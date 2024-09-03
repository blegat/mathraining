# -*- coding: utf-8 -*-
require "spec_helper"

describe "Myfile pages", myfile: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:user) { FactoryGirl.create(:advanced_user) }
  
  let(:sub) { FactoryGirl.create(:subject) } # Don't use name "subject" because it is used for the page
  let(:message) { FactoryGirl.create(:message, subject: sub) }
  
  let(:problem) { FactoryGirl.create(:problem, online: true) }
  let(:submission) { FactoryGirl.create(:submission, problem: problem, status: :correct) }
  let(:correction) { FactoryGirl.create(:correction, submission: submission) }
  
  let(:contest) { FactoryGirl.create(:contest) }
  let(:contestproblem) { FactoryGirl.create(:contestproblem, contest: contest) }
  let(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem) }
  let(:contestcorrection) { contestsolution.contestcorrection }
  
  let(:discussion) { create_discussion_between(root, user, "Bonjour", "Salut") }
  let(:tchatmessage) { discussion.tchatmessages.first }
  
  let(:subjectmyfile) { FactoryGirl.create(:subjectmyfile, myfiletable: sub) }
  let(:messagemyfile) { FactoryGirl.create(:messagemyfile, myfiletable: message) }
  let(:submissionmyfile) { FactoryGirl.create(:submissionmyfile, myfiletable: submission) }
  let(:correctionmyfile) { FactoryGirl.create(:correctionmyfile, myfiletable: correction) }
  let(:contestsolutionmyfile) { FactoryGirl.create(:contestsolutionmyfile, myfiletable: contestsolution) }
  let(:contestcorrectionmyfile) { FactoryGirl.create(:contestcorrectionmyfile, myfiletable: contestcorrection) }
  let(:tchatmessagemyfile) { FactoryGirl.create(:tchatmessagemyfile, myfiletable: tchatmessage) }
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:old_image) { "mathraining.png" } # This one is used for all default files
  let(:new_image) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }

  describe "root" do
    before { sign_in root }
    
    describe "visits all files page" do
      let!(:subjectmyfile) { FactoryGirl.create(:subjectmyfile, myfiletable: sub) } # Force its creation
      before { visit myfiles_path }
      it do
        should have_selector("h1", text: "Pièces jointes")
        should have_link("Voir", href: myfile_path(subjectmyfile))
        should have_link(href: rails_blob_url(subjectmyfile.file, :only_path => true, :disposition => 'attachment'))
      end
    end
    
    describe "visits one subject file" do
      before { visit myfile_path(subjectmyfile) }
      it do
        should have_current_path(subject_path(sub))
        should have_link(subjectmyfile.file.filename.to_s, href: rails_blob_url(subjectmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: myfile_fake_delete_path(subjectmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: myfile_fake_delete_path(subjectmyfile)) }
        it do
          should have_current_path(subject_path(sub, :q => 0))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
      
      describe "and fake deletes it while it was deleted by someone else" do
        before do
          id = subjectmyfile.id
          subjectmyfile.destroy
          click_link("Supprimer le contenu", href: myfile_fake_delete_path(id))
        end
        it { should have_content(error_access_refused) }
      end
    end
    
    describe "visits one message file" do
      before { visit myfile_path(messagemyfile) }
      it do
        should have_current_path(subject_path(sub, :page => 1, :msg => message))
        should have_link(messagemyfile.file.filename.to_s, href: rails_blob_url(messagemyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: myfile_fake_delete_path(messagemyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: myfile_fake_delete_path(messagemyfile)) }
        it do
          should have_current_path(subject_path(sub, :page => 1, :msg => message, :q => 0))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one submission file" do
      before { visit myfile_path(submissionmyfile) }
      it do
        should have_current_path(problem_path(problem, :sub => submission))
        should have_link(submissionmyfile.file.filename.to_s, href: rails_blob_url(submissionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: myfile_fake_delete_path(submissionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: myfile_fake_delete_path(submissionmyfile)) }
        it do
          should have_current_path(problem_path(problem, :sub => submission))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one correction file" do
      before { visit myfile_path(correctionmyfile) }
      it do
        should have_current_path(problem_path(problem, :sub => submission))
        should have_link(correctionmyfile.file.filename.to_s, href: rails_blob_url(correctionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: myfile_fake_delete_path(correctionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: myfile_fake_delete_path(correctionmyfile)) }
        it do
          should have_current_path(problem_path(problem, :sub => submission))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one contestsolution file" do
      before { visit myfile_path(contestsolutionmyfile) }
      it do
        should have_current_path(contestproblem_path(contestproblem, :sol => contestsolution))
        should have_link(contestsolutionmyfile.file.filename.to_s, href: rails_blob_url(contestsolutionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: myfile_fake_delete_path(contestsolutionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: myfile_fake_delete_path(contestsolutionmyfile)) }
        it do
          should have_current_path(contestproblem_path(contestproblem, :sol => contestsolution))
          should have_success_message("Contenu de la pièce jointe supprimé.")
          should have_content("désactivée")
        end
      end
    end
    
    describe "visits one contestcorrection file" do
      before { visit myfile_path(contestcorrectionmyfile) }
      it do
        should have_current_path(contestproblem_path(contestproblem, :sol => contestsolution))
        should have_link(contestcorrectionmyfile.file.filename.to_s, href: rails_blob_url(contestcorrectionmyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: myfile_fake_delete_path(contestcorrectionmyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: myfile_fake_delete_path(contestcorrectionmyfile)) }
        it do
          should have_current_path(contestproblem_path(contestproblem, :sol => contestsolution))
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
      let!(:tchatmessagemyfile) { FactoryGirl.create(:tchatmessagemyfile, myfiletable: tchatmessage) } # Force its creation
      before { visit discussion_path(discussion) }
      it do
        should have_link(tchatmessagemyfile.file.filename.to_s, href: rails_blob_url(tchatmessagemyfile.file, :only_path => true, :disposition => 'attachment'))
        should have_link("Supprimer le contenu", href: myfile_fake_delete_path(tchatmessagemyfile))
      end
      
      describe "and fake deletes it" do
        before { click_link("Supprimer le contenu", href: myfile_fake_delete_path(tchatmessagemyfile)) }
        it do
          should have_current_path(myfiles_path)
          should have_success_message("Contenu de la pièce jointe supprimé.")
        end
      end
    end
  end
  
  describe "cron job" do
    let!(:tchatmessage1) { discussion.tchatmessages.first }
    let!(:tchatmessage2) { discussion.tchatmessages.second }
    
    describe "deletes old files in private messages" do
      before do
        myfile11 = FactoryGirl.create(:tchatmessagemyfile, myfiletable: tchatmessage1)
        myfile12 = FactoryGirl.create(:tchatmessagemyfile, myfiletable: tchatmessage1)
        myfile21 = FactoryGirl.create(:tchatmessagemyfile, myfiletable: tchatmessage2)
        myfile22 = FactoryGirl.create(:tchatmessagemyfile, myfiletable: tchatmessage2)
        myfile11.file.blob.update_attribute(:created_at, DateTime.now - 50.days)
        myfile12.file.blob.update_attribute(:created_at, DateTime.now - 30.days)
        myfile21.file.blob.update_attribute(:created_at, DateTime.now - 26.days)
        myfile22.file.blob.update_attribute(:created_at, DateTime.now - 10.days)
        Myfile.fake_dels
        tchatmessage1.reload
        tchatmessage2.reload
      end
      specify do
        expect(tchatmessage1.myfiles.count).to eq(0)
        expect(tchatmessage1.fakefiles.count).to eq(2)
        expect(tchatmessage1.fakefiles.first.filename).to eq(old_image)
        expect(tchatmessage1.fakefiles.second.filename).to eq(old_image)
        expect(tchatmessage2.myfiles.count).to eq(2)
        expect(tchatmessage2.fakefiles.count).to eq(0)
      end
    end
  end
end
