# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/_intro.html.erb", type: :view, chapter: true do

  let(:root) { FactoryGirl.create(:root) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section_fondation) { FactoryGirl.create(:section, fondation: true) }
  let(:chapter1) { FactoryGirl.create(:chapter, section: section_fondation, level: 1, position: 1, author: nil, publication_date: nil, online: false) }
  let(:chapter2) { FactoryGirl.create(:chapter, section: section_fondation, level: 1, position: 2, author: "Jean Dupont", publication_date: Date.new(2023, 11, 10), online: true, submission_prerequisite: true) }
  let(:chapter3) { FactoryGirl.create(:chapter, section: section_fondation, level: 1, position: 3, author: "Jean Flabour", publication_date: nil, online: true) }
  
  context "if the user is a root" do
    before do
      assign(:current_user, root)
    end
    
    context "and the chapter is very empty" do
      before do
        assign(:section, chapter1.section)
        assign(:chapter, chapter1)
      end
      
      it "renders correctly when allow_edit = false" do
        render partial: "chapters/intro"
        expect(rendered).to have_content("Aucun prérequis.")
        expect(rendered).to have_no_link("Ajouter un prérequis")
        expect(rendered).to have_content(chapter1.description)
        expect(rendered).to have_no_content("Ce chapitre a été créé")
        expect(rendered).to have_no_link("Modifier ce chapitre")
      end
      
      it "renders correctly when allow_edit = true" do
        render partial: "chapters/intro", locals: {allow_edit: true}
        expect(rendered).to have_content("Aucun prérequis.")
        expect(rendered).to have_link("Ajouter un prérequis")
        expect(rendered).to have_link("Modifier ce chapitre")
        expect(rendered).to have_no_content("Déplacer vers le")
        expect(rendered).to have_link("Supprimer ce chapitre")
        expect(rendered).to have_no_content("Ce chapitre est un prérequis pour écrire une soumission à un problème")
        expect(rendered).to have_link("Marquer comme prérequis aux soumissions")
        expect(rendered).to have_no_link("Marquer comme non prérequis aux soumissions")
      end
    end
    
    context "and the chapter is very full" do
      let!(:chapter_prerequisite) { FactoryGirl.create(:chapter, section: chapter2.section, level: chapter2.level, position: chapter2.position - 1) }
      before do
        chapter2.prerequisites << chapter_prerequisite
        assign(:section, chapter2.section)
        assign(:chapter, chapter2)
      end
      
      it "renders correctly when allow_edit = false" do
        render partial: "chapters/intro"
        expect(rendered).to have_link(chapter_prerequisite.name, href: chapter_path(chapter_prerequisite))
        expect(rendered).to have_no_link("Ajouter un prérequis")
        expect(rendered).to have_content(chapter2.description)
        expect(rendered).to have_content("écrit par #{chapter2.author} et")
        expect(rendered).to have_content("mis en ligne le #{ write_date_only(chapter2.publication_date) }.")
        expect(rendered).to have_no_link("Modifier ce chapitre")
      end
      
      it "renders correctly when allow_edit = true" do
        render partial: "chapters/intro", locals: {allow_edit: true}
        expect(rendered).to have_no_link("Ajouter un prérequis") # because online
        expect(rendered).to have_link("Modifier ce chapitre")
        expect(rendered).to have_content("Déplacer vers le")
        expect(rendered).to have_link("haut", href: order_chapter_path(chapter2, :new_position => chapter_prerequisite.position))
        expect(rendered).to have_no_link("bas")
        expect(rendered).to have_no_link("Supprimer ce chapitre") # because online
        expect(rendered).to have_content("Ce chapitre est un prérequis pour écrire une soumission à un problème")
        expect(rendered).to have_no_link("Marquer comme prérequis aux soumissions")
        expect(rendered).to have_link("Marquer comme non prérequis aux soumissions")
      end
    end
  end
  
  context "if the user is not an admin" do
    before do
      assign(:current_user, user)
    end
    
    context "and the chapter is normal" do
      before do
        assign(:chapter, chapter3)
      end
    
      it "renders correctly when allow_edit = true" do
        render partial: "chapters/intro", locals: {allow_edit: true} # should still not be able to edit
        expect(rendered).to have_content("Aucun prérequis.")
        expect(rendered).to have_no_link("Ajouter un prérequis")
        expect(rendered).to have_content("écrit par #{chapter3.author}.")
        expect(rendered).to have_no_content("mis en ligne")
        expect(rendered).to have_content(chapter3.description)
        expect(rendered).to have_no_link("Modifier ce chapitre")
      end
    end
  end
end
