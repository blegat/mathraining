# -*- coding: utf-8 -*-
require "spec_helper"

describe "Subject pages" do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:advanced_user) } # Rating 200 is needed to have access to problems
  
  let!(:category) { FactoryBot.create(:category) }
  let!(:category2) { FactoryBot.create(:category) }
  
  let!(:section) { FactoryBot.create(:section) }
  let!(:chapter) { FactoryBot.create(:chapter, section: section, online: true) }
  let!(:question) { FactoryBot.create(:exercise, chapter: chapter, online: true, position: 1) }
  let!(:problem) { FactoryBot.create(:problem, section: section, online: true) }
  
  let(:sub) { FactoryBot.create(:subject) }
  
  let(:sub_nothing) { FactoryBot.create(:subject) }
  let(:sub_category) { FactoryBot.create(:subject, category: category) }
  let(:sub_section) { FactoryBot.create(:subject, section: section) }
  let(:sub_chapter) { FactoryBot.create(:subject, section: section, chapter: chapter) }
  let(:sub_question) { FactoryBot.create(:subject, section: section, chapter: chapter, question: question) }
  let(:sub_problem) { FactoryBot.create(:subject, section: section, problem: problem) }
  
  let(:title) { "Mon titre" }
  let(:content) { "Mon message" }
  let(:newtitle) { "Mon nouveau titre" }
  let(:newcontent) { "Mon nouveau message" }
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
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
      before { visit subject_path(sub) }
      it { should have_content(error_must_be_connected) }
    end
  end
  
  describe "user" do
    before do
      sign_in user
      # To force the creation of those subjects and put them on the first page:
      sub_nothing.update(:last_comment_time => DateTime.now)
      sub_category.update(:last_comment_time => DateTime.now)
      sub_section.update(:last_comment_time => DateTime.now)
      sub_chapter.update(:last_comment_time => DateTime.now)
      sub_question.update(:last_comment_time => DateTime.now)
      sub_problem.update(:last_comment_time => DateTime.now)
    end
    
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
      before { visit subjects_path(:q => "cat-" + category.id.to_s) }
      
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
      before { visit subjects_path(:q => "sec-" + section.id.to_s) }
      
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
      before { visit subjects_path(:q => "cha-" + chapter.id.to_s) }
      
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
      before { visit subjects_path(:q => "pro-" + section.id.to_s) }
      
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
          should have_success_message("Votre sujet a bien été posté.")
          should have_content("#{title} - #{category.name}")
          should have_selector("div", text: content)
        end
        
        describe "and visit all subjects page" do
          before { visit subjects_path }
          it { should have_link(title) }
        end
      end
      
      describe "and tries to create a subject with empty title" do
        before do
          select category.name, from: "Catégorie"
          fill_in "Titre", with: ""
          fill_in "MathInput", with: content
          click_button "Créer"
        end
        it { should have_error_message("Titre doit être rempli") }
      end
    end
    
    describe "visits a subject page" do
      before { visit subject_path(sub, :page => "last") }
      it do
        should have_content(sub.title)
        should have_no_link("Modifier ce sujet")
        should have_button("Répondre")
      end
      
      describe "and follows the subject" do
        before { click_link("link_follow") }
        specify do
          expect(page).to have_success_message("Vous recevrez dorénavant un e-mail à chaque fois qu'un nouveau message sera posté sur ce sujet.")
          expect(page).to have_link("link_unfollow")
          expect(user.followed_subjects.exists?(sub.id)).to eq(true)
        end
        
        describe "and unfollows the subject" do
          before { click_link("link_unfollow") }
          specify do
            expect(page).to have_success_message("Vous ne recevrez maintenant plus d'e-mail concernant ce sujet.")
            expect(page).to have_link("link_follow")
            expect(user.followed_subjects.exists?(sub.id)).to eq(false)
          end
        end
      end
    end
    
    describe "tries to visit a wepion subject" do
      before { sub.update_attribute(:for_wepion, true) }
      
      describe "while not in wepion" do
        before { visit subject_path(sub) }
        it { should have_content(error_access_refused) }
      end
      
      describe "while in wepion" do
        before do
          user.update_attribute(:wepion, true)
          visit subject_path(sub)
        end
        it do
          should have_content(sub.title)
        end
      end
    end
    
    describe "tries to visit a corrector subject" do
      before { sub.update_attribute(:for_correctors, true) }
      
      describe "while not coorrector" do
        before { visit subject_path(sub) }
        it { should have_content(error_access_refused) }
      end
      
      describe "while corrector" do
        before do
          user.update_attribute(:corrector, true)
          visit subject_path(sub)
        end
        it do
          should have_content(sub.title)
        end
      end
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "visits a subject" do
      before { visit subject_path(sub) }
      specify do
        expect(page).to have_link("Modifier ce sujet")
        expect(page).to have_link("Supprimer ce sujet")
        expect { click_link("Supprimer ce sujet") }.to change(Subject, :count).by(-1)
      end
      
      describe "and edits it" do
        before do
          select category2.name, from: "Catégorie"
          fill_in "Titre", with: newtitle
          click_button "Modifier"
          sub.reload
        end
        specify do
          expect(sub.title).to eq(newtitle)
          expect(sub.category).to eq(category2)
          expect(page).to have_success_message("Le sujet a bien été modifié.")
          expect(page).to have_content("#{newtitle} - #{category2.name}")
        end
      end
    end

    describe "deletes a subject with a message (DEPENDENCY)" do
      let!(:mes) { FactoryBot.create(:message, subject: sub) }
      before { visit subject_path(sub) }
      specify {	expect { click_link("Supprimer ce sujet") }.to change(Message, :count).by(-1) }
    end
    
    describe "visits a wepion subject" do
      before do
        sub.update_attribute(:for_wepion, true)
        visit subject_path(sub)
      end
      it do
        should have_content(sub.title)
      end
    end
    
    describe "visits a corrector subject" do
      before do
        sub.update_attribute(:for_correctors, true)
        visit subject_path(sub)
      end
      it do
        should have_content(sub.title)
      end
    end
  end

  describe "root" do
    before { sign_in root }
    
    describe "visits a subject" do
      let!(:sub1) { FactoryBot.create(:subject) }
      let!(:mes1) { FactoryBot.create(:message, subject: sub1) }
      let!(:sub2) { FactoryBot.create(:subject) }
      let!(:mes2) { FactoryBot.create(:message, subject: sub2) }
      before do
        visit subject_path(sub2)
      end
      it { should have_link("Migrer ce sujet") }
      
      describe "and migrates it" do
        let!(:old_title) { sub2.title }
        let!(:old_num_subjects) { Subject.count }
        let!(:old_num_messages) { Message.count }
        before do
          fill_in "migreur", with: sub1.id
          click_button "Migrer"
          sub1.reload
          mes1.reload
          mes2.reload
        end
        specify do
          expect(page).to have_content(sub1.title)
          expect(page).to have_content(mes1.content)
          expect(Subject.count).to eq(old_num_subjects - 1)
          expect(Message.count).to eq(old_num_messages)
          expect(mes2.content).to include(old_title) # In the remark saying that the message was migrated
          expect(mes2.subject).to eq(sub1)
          expect(mes1.subject).to eq(sub1)
          expect(sub1.last_comment_user_id).to eq(mes2.user_id)
        end
      end
      
      describe "and migrates it to a wrong subject" do
        before do
          fill_in "migreur", with: Subject.order(:id).last.id + 1
          click_button "Migrer"
        end
        it { should have_error_message("Ce sujet n'existe pas.") }
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user", :js => true do
    before { sign_in user }
    
    describe "creates a subject with a file" do
      before do
        visit new_subject_path
        fill_in "Titre", with: title
        fill_in "MathInput", with: content
        wait_for_js_imports
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image1))
        click_button "Créer"
      end
      let(:newsubject) { Subject.order(:id).last }
      specify do
        expect(newsubject.title).to eq(title)
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.messages.first.myfiles.count).to eq(1)
        expect(newsubject.messages.first.myfiles.first.file.filename.to_s).to eq(image1)
      end
    end
    
    describe "tries to create a subject with a exe file" do
      before do
        visit new_subject_path
        fill_in "Titre", with: title
        fill_in "MathInput", with: content
        wait_for_js_imports
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
        click_button "Créer"
      end
      it do
        should have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
        should have_selector("h1", text: "Créer un sujet")
      end
    end
    
    describe "creates a subject in relation with a section" do
      before do
        visit new_subject_path
        wait_for_js_imports
        select section.name, from: "Catégorie"
        fill_in "Titre", with: title
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq(title)
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(nil)
        expect(newsubject.section).to eq(section)
        expect(newsubject.chapter).to eq(nil)
        expect(newsubject.question).to eq(nil)
        expect(newsubject.problem).to eq(nil)
      end
    end
    
    describe "creates a subject in relation with a chapter" do
      before do
        visit new_subject_path
        wait_for_js_imports
        select section.name, from: "Catégorie"
        wait_for_ajax
        select chapter.name, from: "Chapitre"
        fill_in "Titre", with: title
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq(title)
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(nil)
        expect(newsubject.section).to eq(section)
        expect(newsubject.chapter).to eq(chapter)
        expect(newsubject.question).to eq(nil)
        expect(newsubject.problem).to eq(nil)
      end
    end
    
    describe "creates a subject in relation with an exercise" do
      let!(:question2) { FactoryBot.create(:exercise, chapter: chapter, online: true, position: 2) }
      before do
        visit new_subject_path
        wait_for_js_imports
        select section.name, from: "Catégorie"
        wait_for_ajax
        select chapter.name, from: "Chapitre"
        wait_for_ajax
        select "Exercice 2", from: "Exercice" # NB: Exercise 1 should not appear because there is already a subject!
        wait_for_ajax # Titre should be automatically filled with "Exercice 2"
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq("Exercice 2")
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(nil)
        expect(newsubject.section).to eq(section)
        expect(newsubject.chapter).to eq(chapter)
        expect(newsubject.question).to eq(question2)
        expect(newsubject.problem).to eq(nil)
      end
    end
    
    describe "creates a subject in relation with a problem" do
      let!(:problem2) { FactoryBot.create(:problem, section: section, online: true) }
      before do
        visit new_subject_path
        wait_for_js_imports
        select section.name, from: "Catégorie"
        wait_for_ajax
        select "Problèmes de #{section.name.downcase}", from: "Chapitre"
        wait_for_ajax
        select "Problème \##{problem2.number}", from: "Problème" # NB: problem should not appear because there is already a subject!
        wait_for_ajax # Titre should be automaticaly filled with "Problème #..."
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq("Problème \##{problem2.number}")
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(nil)
        expect(newsubject.section).to eq(section)
        expect(newsubject.chapter).to eq(nil)
        expect(newsubject.question).to eq(nil)
        expect(newsubject.problem).to eq(problem2)
      end
    end
    
    describe "creates a subject in relation with no problem" do
      before do
        visit new_subject_path
        wait_for_js_imports
        select section.name, from: "Catégorie"
        wait_for_ajax
        select "Problèmes de #{section.name.downcase}", from: "Chapitre"
        wait_for_ajax
        fill_in "Titre", with: title
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      it { should have_error_message("Un problème doit être sélectionné.") }
    end
    
    describe "creates a subject when category filter is used" do
      before do
        visit new_subject_path(:q => "cat-" + category2.id.to_s)
        fill_in "Titre", with: title
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq(title)
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(category2)
        expect(newsubject.section).to eq(nil)
        expect(newsubject.chapter).to eq(nil)
        expect(newsubject.question).to eq(nil)
        expect(newsubject.problem).to eq(nil)
      end
    end
    
    describe "creates a subject when section filter is used" do
      before do
        visit new_subject_path(:q => "sec-" + section.id.to_s)
        wait_for_js_imports
        select chapter.name, from: "Chapitre"
        wait_for_ajax
        fill_in "Titre", with: title
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq(title)
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(nil)
        expect(newsubject.section).to eq(section)
        expect(newsubject.chapter).to eq(chapter)
        expect(newsubject.question).to eq(nil)
        expect(newsubject.problem).to eq(nil)
      end
    end
    
    describe "creates a subject when problems of a section filter is used" do
    let!(:problem2) { FactoryBot.create(:problem, section: section, online: true) }
      before do
        visit new_subject_path(:q => "pro-" + section.id.to_s)
        wait_for_js_imports
        select "Problème \##{problem2.number}", from: "Problème" # NB: problem should not appear because there is already a subject!
        wait_for_ajax # Titre should be automaticaly filled with "Problème #..."
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq("Problème \##{problem2.number}")
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(nil)
        expect(newsubject.section).to eq(section)
        expect(newsubject.chapter).to eq(nil)
        expect(newsubject.question).to eq(nil)
        expect(newsubject.problem).to eq(problem2)
      end
    end
    
    describe "creates a subject when chapter filter is used" do
    let!(:question2) { FactoryBot.create(:exercise, chapter: chapter, online: true, position: 2) }
      before do
        visit new_subject_path(:q => "cha-" + chapter.id.to_s)
        wait_for_js_imports
        select "Exercice 2", from: "Exercice" # NB: Exercise 1 should not appear because there is already a subject!
        wait_for_ajax # Titre should be automatically filled with "Exercice 2"
        fill_in "MathInput", with: content
        click_button "Créer"
      end
      let!(:newsubject) { Subject.order(:id).last }
      specify do
        expect(page).to have_success_message("Votre sujet a bien été posté.")
        expect(newsubject.title).to eq("Exercice 2")
        expect(newsubject.messages.first.content).to eq(content)
        expect(newsubject.category).to eq(nil)
        expect(newsubject.section).to eq(section)
        expect(newsubject.chapter).to eq(chapter)
        expect(newsubject.question).to eq(question2)
        expect(newsubject.problem).to eq(nil)
      end
    end
  end
  
  describe "root", :js => true do
    before { sign_in root }
    
    let!(:other_section) { FactoryBot.create(:section) }
    let!(:other_chapter) { FactoryBot.create(:chapter, section: section, online: true) }
    let!(:other_question) { FactoryBot.create(:question, chapter: other_chapter, online: true) }
    let!(:other_problem) { FactoryBot.create(:problem, section: section, online: true) }
    
    describe "updates a subject, from a question to a section" do
      before do
        visit subject_path(sub_question)
        wait_for_js_imports
        click_link "Modifier ce sujet"
        wait_for_ajax
        select other_section.name, from: "Catégorie"
        wait_for_ajax
        fill_in "Titre", with: newtitle
        click_button "Modifier"
        sub_question.reload
      end
      specify do
        expect(page).to have_success_message("Le sujet a bien été modifié.")
        expect(sub_question.title).to eq(newtitle)
        expect(sub_question.section).to eq(other_section)
        expect(sub_question.chapter).to eq(nil)
        expect(sub_question.question).to eq(nil)
        expect(sub_question.problem).to eq(nil)
      end
    end
    
    describe "updates a suject, from a category to a chapter" do
      before do
        visit subject_path(sub_category)
        wait_for_js_imports
        click_link "Modifier ce sujet"
        wait_for_ajax
        select section.name, from: "Catégorie"
        wait_for_ajax
        select other_chapter.name, from: "Chapitre"
        fill_in "Titre", with: newtitle
        click_button "Modifier"
        sub_category.reload
      end
      specify do
        expect(page).to have_success_message("Le sujet a bien été modifié.")
        expect(sub_category.title).to eq(newtitle)
        expect(sub_category.section).to eq(section)
        expect(sub_category.chapter).to eq(other_chapter)
        expect(sub_category.question).to eq(nil)
        expect(sub_category.problem).to eq(nil)
      end
    end
    
    describe "updates a suject, from a chapter to a question" do
      before do
        visit subject_path(sub_chapter)
        wait_for_js_imports
        click_link "Modifier ce sujet"
        wait_for_ajax
        select other_chapter.name, from: "Chapitre"
        wait_for_ajax
        select "Exercice 1", from: "Exercice"
        wait_for_ajax # Titre should be automatically filled with "Exercice 1"
        click_button "Modifier"
        sub_chapter.reload
      end
      specify do
        expect(page).to have_success_message("Le sujet a bien été modifié.")
        expect(sub_chapter.title).to eq("Exercice 1")
        expect(sub_chapter.section).to eq(section)
        expect(sub_chapter.chapter).to eq(other_chapter)
        expect(sub_chapter.question).to eq(other_question)
        expect(sub_chapter.problem).to eq(nil)
      end
    end
    
    describe "updates a suject, from a chapter to a problem" do
      before do
        visit subject_path(sub_chapter)
        wait_for_js_imports
        click_link "Modifier ce sujet"
        wait_for_ajax
        select "Problèmes de #{section.name.downcase}", from: "Chapitre"
        wait_for_ajax
        select "Problème \##{other_problem.number}", from: "Problème"
        wait_for_ajax # Titre should be automatically filled with "Problème #..."
        click_button "Modifier"
        sub_chapter.reload
      end
      specify do
        expect(page).to have_success_message("Le sujet a bien été modifié.")
        expect(sub_chapter.title).to eq("Problème \##{other_problem.number}")
        expect(sub_chapter.section).to eq(section)
        expect(sub_chapter.chapter).to eq(nil)
        expect(sub_chapter.question).to eq(nil)
        expect(sub_chapter.problem).to eq(other_problem)
      end
    end
    
    describe "updates a suject, from a question to no problem" do
      before do
        visit subject_path(sub_question)
        wait_for_js_imports
        click_link "Modifier ce sujet"
        wait_for_ajax
        select "Problèmes de #{section.name.downcase}", from: "Chapitre"
        fill_in "Titre", with: newtitle
        click_button "Modifier"
        sub_question.reload
      end
      it { should have_error_message("Un problème doit être sélectionné.") }
    end
  end
end
