# -*- coding: utf-8 -*-
require "spec_helper"

describe "Subject pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }
  
  let!(:category) { FactoryGirl.create(:category) }
  let!(:category2) { FactoryGirl.create(:category) }
  
  let!(:section) { FactoryGirl.create(:section) }
  let!(:chapter) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:question) { FactoryGirl.create(:exercise, chapter: chapter, online: true) }
  let!(:problem) { FactoryGirl.create(:problem, section: section, online: true) }
  
  let!(:sub) { FactoryGirl.create(:subject) }
  let!(:sub_user) { FactoryGirl.create(:subject, user: user) }
  let!(:sub_other_user) { FactoryGirl.create(:subject, user: other_user) }
  let!(:sub_admin) { FactoryGirl.create(:subject, user: admin) }
  let!(:sub_other_admin) { FactoryGirl.create(:subject, user: other_admin) }
  let!(:sub_other_root) { FactoryGirl.create(:subject, user: other_root) }
  
  let!(:sub_nothing) { FactoryGirl.create(:subject, user: user) }
  let!(:sub_category) { FactoryGirl.create(:subject, user: other_user, category: category) }
  let!(:sub_section) { FactoryGirl.create(:subject, user: admin, section: section) }
  let!(:sub_chapter) { FactoryGirl.create(:subject, user: other_admin, section: section, chapter: chapter) }
  let!(:sub_question) { FactoryGirl.create(:subject, user: root, section: section, chapter: chapter, question: question) }
  let!(:sub_problem) { FactoryGirl.create(:subject, user: other_root, section: section, problem: problem) }

  let(:title) { "Mon titre" }
  let(:content) { "Mon message" }
  let(:newtitle) { "Mon nouveau titre" }
  let(:newcontent) { "Mon nouveau message" }
  
  describe "visitor" do
    describe "tries to visit subjects page" do
      before { visit subjects_path }
      it { should have_content(error_must_be_connected) }
    end
    
    describe "tries to create a subject" do
      before { visit new_subject_path }
      it { should have_content(error_must_be_connected) }
    end
    
    describe "tries to visit a subject" do
      before { visit subject_path(sub_user) }
      it { should have_content(error_must_be_connected) }
    end
  end
  
  describe "user" do
    before { sign_in user }
    
    describe "visits subjects page" do
      before { visit subjects_path }
      it do
        should have_selector("h1", text: "Forum")
        should have_link("Créer un sujet")
      
        should have_link(sub_nothing.title)
        should have_link(sub_category.title)
        should have_link(sub_section.title)
        should have_link(sub_chapter.title)
        should have_link(sub_question.title)
        should have_link(sub_problem.title)
      end
    end
    
    describe "visit subjects page for a category" do
      before { visit subjects_path(:q => category.id * 1000000) }
      
      it do
        should have_no_link(sub_nothing.title)
        should have_link(sub_category.title)
        should have_no_link(sub_section.title)
        should have_no_link(sub_chapter.title)
        should have_no_link(sub_question.title)
        should have_no_link(sub_problem.title)
      end
    end
    
    describe "visit subjects page for a section" do
      before { visit subjects_path(:q => section.id * 1000) }
      
      it do
        should have_no_link(sub_nothing.title)
        should have_no_link(sub_category.title)
        should have_link(sub_section.title)
        should have_link(sub_chapter.title)
        should have_link(sub_question.title)
        should have_link(sub_problem.title)
      end
    end
    
    describe "visit subjects page for a chapter" do
      before { visit subjects_path(:q => chapter.id) }
      
      it do
        should have_no_link(sub_nothing.title)
        should have_no_link(sub_category.title)
        should have_no_link(sub_section.title)
        should have_link(sub_chapter.title)
        should have_link(sub_question.title)
        should have_no_link(sub_problem.title)
      end
    end
    
    describe "visit subjects page for problems of a section" do
      before { visit subjects_path(:q => section.id * 1000 + 1) }
      
      it do
        should have_no_link(sub_nothing.title)
        should have_no_link(sub_category.title)
        should have_no_link(sub_section.title)
        should have_no_link(sub_chapter.title)
        should have_no_link(sub_question.title)
        should have_link(sub_problem.title)
      end
    end
    
    describe "visits subject creation page" do
      before { visit new_subject_path }
      it { should have_selector("h1", text: "Créer un sujet") }

      describe "and creates a subject" do
        before do
          select category.name, from: "Catégorie"
          fill_in "Titre", with: title
          fill_in "MathInput", with: content
          click_button "Créer"
        end
        it do
          should have_content("Votre sujet a bien été posté.")
          should have_content("#{title} - #{category.name}")
          should have_selector("div", text: content)
        end
        
        describe "and visit all subjects page" do
          before { visit subjects_path }
          it { should have_link(title) }
        end
      end
    end
    
    describe "visits his subject page" do
      before { visit subject_path(sub_user) }
      it do
        should have_content(sub_user.title)
        should have_link("Modifier ce sujet")
        should have_button("Répondre")
      end
      
      describe "and edits it" do
        before do
          select category2.name, from: "Catégorie"
          fill_in "Titre", with: newtitle
          fill_in "MathInputEditSubject", with: newcontent
          click_button "Modifier"
        end
        it do
          should have_content("Votre sujet a bien été modifié.")
          should have_content("#{newtitle} - #{category2.name}")
          should have_selector("div", text: newcontent)
        end
      end
    end
    
    describe "visits the subject of another user" do
      before { visit subject_path(sub_other_user) }
      it do
        should have_content(sub_other_user.title)
        should have_no_link("Modifier ce sujet")
        should have_no_button("Modifier")
        should have_button("Répondre")
      end
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "visits the subject of a student" do
      before { visit subject_path(sub) }
      it do
        should have_link("Modifier ce sujet")
        should have_link("Supprimer ce sujet")
      end
      
      specify { expect { click_link("Supprimer ce sujet") }.to change(Subject, :count).by(-1) }
      
      describe "and edits it" do
        before do
          select category2.name, from: "Catégorie"
          fill_in "Titre", with: newtitle
          fill_in "MathInputEditSubject", with: newcontent
          click_button "Modifier"
        end
        it do
          should have_content("Votre sujet a bien été modifié.")
          should have_content("#{newtitle} - #{category2.name}")
          should have_selector("div", text: newcontent)
        end
      end
    end

    describe "visits his subject" do
      before { visit subject_path(sub_admin) }
      it { should have_link("Supprimer ce sujet") }
      
      specify {	expect { click_link("Supprimer ce sujet") }.to change(Subject, :count).by(-1) }
    end
    
    describe "tries to edit the subject of another admin" do
      before { visit subject_path(sub_other_admin) }
      it do
        should have_no_link("Modifier ce sujet")
        should have_no_button("Modifier")
      end
    end

    describe "deletes a subject with a message (DEPENDENCY)" do
      let!(:mes) { FactoryGirl.create(:message, subject: sub) }
      before { visit subject_path(sub) }
      specify {	expect { click_link("Supprimer ce sujet") }.to change(Message, :count).by(-1) }
    end
  end

  describe "root" do
    before { sign_in root }

    describe "visits the subject of another root" do
      before { visit subject_path(sub_other_root) }
      it do
        should have_link("Modifier ce sujet")
        should have_link("Supprimer ce sujet")
      end
      
      specify { expect { click_link("Supprimer ce sujet") }.to change(Subject, :count).by(-1) }
      
      describe "and edits it" do
        before do
          select category2.name, from: "Catégorie"
          fill_in "Titre", with: newtitle
          fill_in "MathInputEditSubject", with: newcontent
          click_button "Modifier"
        end
        it do
          should have_content("Votre sujet a bien été modifié.")
          should have_content("#{newtitle} - #{category2.name}")
          should have_selector("div", text: newcontent)
        end
      end
    end
    
    describe "visits the subject of an user" do
      let!(:mes) { FactoryGirl.create(:message, subject: sub_other_user) }
      before do
        # Set lastcomment and lastcomment_user_id correctly for sub_user and sub_other_user
        sub_user.lastcomment = sub_user.created_at
        sub_user.lastcomment_user_id = sub_user.user_id
        sub_user.save
        sub_other_user.lastcomment = mes.created_at
        sub_other_user.lastcomment_user_id = mes.user_id
        sub_other_user.save
        visit subject_path(sub_other_user)
      end
      it { should have_link("Migrer ce sujet") }
      
      describe "and migrates it" do
        let!(:old_title) { sub_other_user.title }
        let!(:old_content) { sub_other_user.content }
        let!(:old_num_subjects) { Subject.count }
        let!(:old_num_messages) { Message.count }
        before do
          fill_in "migreur", with: sub_user.id
          click_button "Do it !"
          sub_user.reload
          mes.reload
        end
        it do
          should have_content(sub_user.title)
          should have_content(old_content)
          should have_content(mes.content)
        end
        specify do
          expect(Subject.count).to eq(old_num_subjects - 1)
          expect(Message.count).to eq(old_num_messages + 1)
          expect(Message.order(:id).last.content).to include(old_content)
          expect(Message.order(:id).last.content).to include(old_title) # In the remark saying that the message was migrated
          expect(Message.order(:id).last.subject).to eq(sub_user)
          expect(mes.subject).to eq(sub_user)
          expect(sub_user.lastcomment_user_id).to eq(mes.user_id)
        end
      end
      
      describe "and migrates it to a wrong subject" do
        before do
          fill_in "migreur", with: Subject.order(:id).last.id + 1
          click_button "Do it !"
        end
        it { should have_content("Ce sujet n'existe pas.") }
      end
      
      describe "and migrates it to an older subject" do
        before do
          sub_user.created_at = sub_other_user.created_at + 1.day
          sub_user.save
          fill_in "migreur", with: sub_user.id
          click_button "Do it !"
        end
        it { should have_content("Le sujet le plus récent doit être migré vers le sujet le moins récent.") }
      end
    end
  end
end
