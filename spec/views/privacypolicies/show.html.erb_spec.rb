# -*- coding: utf-8 -*-
require "spec_helper"

describe "privacypolicies/show.html.erb", type: :view, privacypolicy: true do

  let(:root) { FactoryGirl.create(:root) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:privacypolicy1) { FactoryGirl.create(:privacypolicy, publication_time: DateTime.now - 100.days, online: true) }
  let!(:privacypolicy2) { FactoryGirl.create(:privacypolicy, publication_time: DateTime.now - 50.days, online: true) }
  let!(:privacypolicy3) { FactoryGirl.create(:privacypolicy, publication_time: DateTime.now - 10.days, online: true) }
  let!(:privacypolicy4) { FactoryGirl.create(:privacypolicy, online: false) }
  
  context "if the user is a root" do
    before do
      assign(:current_user, root)
      assign(:privacypolicy, privacypolicy3)
    end
    
    it "renders the update button" do
      render template: "privacypolicies/show"
      expect(rendered).to have_link("Mettre à jour la politique de confidentialité")
    end
  end
  
  context "if the user is not an admin" do
    before do
      assign(:current_user, user)
    end
    
    context "if this is the first version " do
      before { assign(:privacypolicy, privacypolicy1) }
      
      it "renders the privacypolicy correctly and not the update buttons" do
        render template: "privacypolicies/show"
        expect(rendered).to have_selector("b", text: "Version du #{write_date_only(privacypolicy1.publication_time)}")
        expect(rendered).to have_link("Version du #{write_date_only(privacypolicy2.publication_time)}", href: privacypolicy_path(privacypolicy2))
        expect(rendered).to have_no_text("(dernière version)")
        expect(rendered).to have_content(privacypolicy1.content)
        expect(rendered).to have_no_link("Mettre à jour la politique de confidentialité")
      end
    end
    
    context "if this is the second version " do
      before { assign(:privacypolicy, privacypolicy2) }
      
      it "renders the privacypolicy correctly and not the update buttons" do
        render template: "privacypolicies/show"
        expect(rendered).to have_link("Version du #{write_date_only(privacypolicy1.publication_time)}", href: privacypolicy_path(privacypolicy1))
        expect(rendered).to have_selector("b", text: "Version du #{write_date_only(privacypolicy2.publication_time)}")
        expect(rendered).to have_link("Version du #{write_date_only(privacypolicy3.publication_time)}", href: privacypolicy_path(privacypolicy3))
        expect(rendered).to have_no_text("(dernière version)")
        expect(rendered).to have_content(privacypolicy2.content)
      end
    end
    
    context "if this is the last (online) version " do
      before { assign(:privacypolicy, privacypolicy3) }
      
      it "renders the privacypolicy correctly and not the update buttons" do
        render template: "privacypolicies/show"
        expect(rendered).to have_link("Version du #{write_date_only(privacypolicy2.publication_time)}", href: privacypolicy_path(privacypolicy2))
        expect(rendered).to have_selector("b", text: "Version du #{write_date_only(privacypolicy3.publication_time)}")
        expect(rendered).to have_text("(dernière version)")
        expect(rendered).to have_content(privacypolicy3.content)
      end
    end
  end
end
