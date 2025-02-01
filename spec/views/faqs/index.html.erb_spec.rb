# -*- coding: utf-8 -*-
require "spec_helper"

describe "faqs/index.html.erb", type: :view, faq: true do

  subject { rendered }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:faq) { FactoryGirl.create(:faq, position: 1) }
  let!(:faq2) { FactoryGirl.create(:faq, position: 3) }
  
  before { assign(:faqs, Faq.all) }
  
  context "if the user is an admin" do
    before { sign_in_view(admin) }
    
    it "renders the faq and the modify buttons" do
      render template: "faqs/index"
      should have_content(faq.question)
      should have_content(faq.answer)
      should have_content(faq2.question)
      should have_content(faq2.answer)
      should have_link("Modifier la question")
      should have_link("Supprimer la question")
      should have_link("bas", href: order_faq_path(faq, :new_position => 3))
      should have_link("haut", href: order_faq_path(faq2, :new_position => 1))
      should have_link("Ajouter une question")
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_view(user) }
    
    it "renders the faq and not the modify buttons" do
      render template: "faqs/index"
      should have_content(faq.question)
      should have_content(faq.answer)
      should have_content(faq2.question)
      should have_content(faq2.answer)
      should have_no_link("Modifier la question")
      should have_no_link("Supprimer la question")
      should have_no_link("bas")
      should have_no_link("haut")
      should have_no_link("Ajouter une question")
    end
  end
  
  context "if the user is not signed in" do    
    it "renders the faq and not the modify buttons" do
      render template: "faqs/index"
      should have_content(faq.question)
      should have_content(faq.answer)
      should have_content(faq2.question)
      should have_content(faq2.answer)
      should have_no_link("Modifier la question")
      should have_no_link("Supprimer la question")
      should have_no_link("bas")
      should have_no_link("haut")
      should have_no_link("Ajouter une question")
    end
  end
end
