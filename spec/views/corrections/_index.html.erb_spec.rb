# -*- coding: utf-8 -*-
require "spec_helper"

describe "corrections/_index.html.erb", type: :view, correction: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user) }
  let(:submission) { FactoryGirl.create(:submission, user: user) }
  
  before do
    assign(:submission, submission)
  end
  
  context "if the user is the submission owner" do
    before do
      assign(:current_user, user)
    end
    
    context "and there is no correction" do
      before do
        submission.waiting!
      end
      
      it "renders no correction" do
        render partial: "corrections/index"
        expect(rendered).to have_content("Aucun commentaire")
        expect(response).not_to render_template(:partial => "shared/_post")
        expect(rendered).to have_no_content("Votre solution est erronée")
      end
    end
    
    context "and there are some corrections" do
      let!(:correction1) { FactoryGirl.create(:correction, submission: submission, user: user) }
      let!(:correction2) { FactoryGirl.create(:correction, submission: submission, user: admin, created_at: correction1.created_at + 1.minute) }
      
      before do
        submission.wrong!
      end
      
      it "renders the corrections correctly" do
        render partial: "corrections/index"
        expect(rendered).to have_no_content("Aucun commentaire")
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction1, kind: "correction"})
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction2, kind: "correction"})
        expect(rendered).to have_content("Votre solution est erronée")
      end
      
      context "and there is one more correction from the user" do
        let!(:correction3) { FactoryGirl.create(:correction, submission: submission, user: user, created_at: correction2.created_at + 1.minute) }
        
        it "does not render the message about how to correct a solution anymore" do
          render partial: "corrections/index"
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction3, kind: "correction"})
          expect(rendered).to have_no_content("Votre solution est erronée")
        end
      end
    end
  end
  
  context "if the user is not the submission owner" do
    before do
      assign(:current_user, admin)
    end
    
    context "and the submission is wrong" do
      let!(:correction) { FactoryGirl.create(:correction, submission: submission, user: admin) }
      
      before do
        submission.wrong!
      end
      
      it "does not render the message about how to correct a solution" do
        render partial: "corrections/index"
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction, kind: "correction"})
        expect(rendered).to have_no_content("Votre solution est erronée")
      end
    end
  end
end
