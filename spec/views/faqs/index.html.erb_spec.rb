# -*- coding: utf-8 -*-
require "spec_helper"

describe "faqs/index.html.erb", type: :view, faq: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:faq) { FactoryGirl.create(:faq, position: 1) }
  let!(:faq2) { FactoryGirl.create(:faq, position: 3) }
  
  before do
    assign(:faqs, Faq.all)
  end
  
  context "if the user is an admin" do
    before do
      assign(:current_user, admin)
    end
    
    it "renders the faq and the modify buttons" do
      render template: "faqs/index"
      expect(rendered).to have_content(faq.question)
      expect(rendered).to have_content(faq.answer)
      expect(rendered).to have_content(faq2.question)
      expect(rendered).to have_content(faq2.answer)
      expect(rendered).to have_link("Modifier la question")
      expect(rendered).to have_link("Supprimer la question")
      expect(rendered).to have_link("bas", href: order_faq_path(faq, :new_position => 3))
      expect(rendered).to have_link("haut", href: order_faq_path(faq2, :new_position => 1))
      expect(rendered).to have_button("Ajouter une question")
    end
  end
  
  context "if the user is not an admin" do
    before do
      assign(:current_user, user)
    end
    
    it "renders the faq and not the modify buttons" do
      render template: "faqs/index"
      expect(rendered).to have_content(faq.question)
      expect(rendered).to have_content(faq.answer)
      expect(rendered).to have_content(faq2.question)
      expect(rendered).to have_content(faq2.answer)
      expect(rendered).to have_no_link("Modifier la question")
      expect(rendered).to have_no_link("Supprimer la question")
      expect(rendered).to have_no_link("bas")
      expect(rendered).to have_no_link("haut")
      expect(rendered).to have_no_button("Ajouter une question")
    end
  end
  
  context "if the user is not signed in" do    
    it "renders the faq and not the modify buttons" do
      render template: "faqs/index"
      expect(rendered).to have_content(faq.question)
      expect(rendered).to have_content(faq.answer)
      expect(rendered).to have_content(faq2.question)
      expect(rendered).to have_content(faq2.answer)
      expect(rendered).to have_no_link("Modifier la question")
      expect(rendered).to have_no_link("Supprimer la question")
      expect(rendered).to have_no_link("bas")
      expect(rendered).to have_no_link("haut")
      expect(rendered).to have_no_button("Ajouter une question")
    end
  end
end
