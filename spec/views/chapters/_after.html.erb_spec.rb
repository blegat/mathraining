# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/_after.html.erb", type: :view, chapter: true do

  subject { rendered }

  let(:root) { FactoryBot.create(:root) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  
  context "if the chapter is online" do
    let!(:chapter) { FactoryBot.create(:chapter, online: true) }
    
    before do
      assign(:section, chapter.section)
      assign(:chapter, chapter)
    end
    
    context "and the user is not signed in" do
      before { sign_in_view(user) }
      
      it "does not render any link" do
        render partial: "chapters/after"
        should have_no_link("point théorique")
        should have_no_link("exercice")
        should have_no_link("QCM")
        should have_no_link("Mettre ce chapitre en ligne")
      end
    end
  
    context "and the user is not an admin" do
      before { sign_in_view(user) }
      
      it "does not render any link" do
        render partial: "chapters/after"
        should have_no_link("point théorique")
        should have_no_link("exercice")
        should have_no_link("QCM")
        should have_no_link("Mettre ce chapitre en ligne")
      end
    end
  
    context "and the user is an admin" do
      before { sign_in_view(admin) }
      
      it "renders links but not the one to put online" do
        render partial: "chapters/after"
        should have_link("point théorique")
        should have_link("exercice")
        should have_link("QCM")
        should have_no_link("Mettre ce chapitre en ligne")
      end
    end
  
    context "and the user is a root" do
      before { sign_in_view(root) }
    
      it "renders links but not the one to put online" do
        render partial: "chapters/after"
        should have_link("point théorique")
        should have_link("exercice")
        should have_link("QCM")
        should have_no_link("Mettre ce chapitre en ligne")
      end
    end
  end
  
  context "if the chapter is offline" do
    let!(:chapter) { FactoryBot.create(:chapter, online: false) }
    
    before do
      assign(:section, chapter.section)
      assign(:chapter, chapter)
    end
    
    context "and the user is not an admin" do # When user creating chapter
      before { sign_in_view(user) }
      
      it "renders links but not the one to put online" do
        render partial: "chapters/after"
        should have_link("point théorique")
        should have_link("exercice")
        should have_link("QCM")
        should have_no_link("Mettre ce chapitre en ligne")
      end
    end
  
    context "and the user is an admin" do
      before { sign_in_view(admin) }
      
      it "renders links but not the one to put online" do
        render partial: "chapters/after"
        should have_link("point théorique")
        should have_link("exercice")
        should have_link("QCM")
        should have_no_link("Mettre ce chapitre en ligne")
      end
    end
  
    context "and the user is a root" do
      before { sign_in_view(root) }
    
      it "renders links, including the one to put online" do
        render partial: "chapters/after"
        should have_link("point théorique")
        should have_link("exercice")
        should have_link("QCM")
        should have_link("Mettre ce chapitre en ligne")
      end
    end
  end
end
