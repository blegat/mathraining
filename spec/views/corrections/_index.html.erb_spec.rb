# -*- coding: utf-8 -*-
require "spec_helper"

describe "corrections/_index.html.erb", type: :view, correction: true do

  subject { rendered }

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user) }
  let(:submission) { FactoryBot.create(:submission, user: user) }
  
  before { assign(:submission, submission) }
  
  context "if the user is the submission owner" do
    before { sign_in_view(user) }
    
    context "and there is no correction" do
      before { submission.waiting! }
      
      it "renders no correction" do
        render partial: "corrections/index"
        should have_content("Aucun commentaire")
        expect(response).not_to render_template(:partial => "shared/_post")
        should have_no_content("Votre solution est erronée")
      end
    end
    
    context "and there are some corrections" do
      let!(:correction1) { FactoryBot.create(:correction, submission: submission, user: user) }
      let!(:correction2) { FactoryBot.create(:correction, submission: submission, user: admin, created_at: correction1.created_at + 1.minute) }
      
      before { submission.wrong! }
      
      it "renders the corrections correctly" do
        render partial: "corrections/index"
        should have_no_content("Aucun commentaire")
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction1})
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction2})
        should have_content("Votre solution est erronée")
      end
      
      context "and there is one more correction from the user" do
        let!(:correction3) { FactoryBot.create(:correction, submission: submission, user: user, created_at: correction2.created_at + 1.minute) }
        
        it "does not render the message about how to correct a solution anymore" do
          render partial: "corrections/index"
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction3})
          should have_no_content("Votre solution est erronée")
        end
      end
    end
  end
  
  context "if the user is not the submission owner" do
    before { sign_in_view(admin) }
    
    context "and the submission is wrong" do
      let!(:correction) { FactoryBot.create(:correction, submission: submission, user: admin) }
      
      before { submission.wrong! }
      
      it "does not render the message about how to correct a solution" do
        render partial: "corrections/index"
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: correction})
        should have_no_content("Votre solution est erronée")
      end
    end
  end
end
