# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestsolutions/_line.html.erb", type: :view, contestsolution: true do

  subject { rendered }

  let(:contest) { FactoryBot.create(:contest, status: :in_progress) }
  let(:contestproblem1_corrected) { FactoryBot.create(:contestproblem, contest: contest, status: :corrected) }
  let(:contestproblem2_in_correction) { FactoryBot.create(:contestproblem, contest: contest, status: :in_correction) }
  
  let(:organizer) { FactoryBot.create(:user) }
  let(:user) { FactoryBot.create(:user) }
  
  let(:contestsolution1) { FactoryBot.create(:contestsolution, contestproblem: contestproblem1_corrected, user: user) }
  let(:contestsolution2) { FactoryBot.create(:contestsolution, contestproblem: contestproblem2_in_correction, user: user) }
  
  RSpec::Matchers.define :have_contestsolution_line do |id, color_class, icon, name, score|
    match do |page|
      expect(page).to have_selector("tr", class: color_class)
      expect(page).to have_icon(icon)
      expect(page).to have_selector("#user_#{id}", text: name)
      expect(page).to have_selector("#score_#{id}", text: score)
    end
  end
  
  before do
    contest.organizers << organizer
    assign(:contest, contest)
  end
  
  context "if user is an organizer" do
    before { sign_in_view(organizer) }
    
    context "and solution is official" do
       before do
        contestsolution1.update(:official => true, :user_id => 0, :corrected => true, :score => 7, :star => true)
        contestsolution2.update(:official => true, :user_id => 0, :corrected => true, :score => 0)
      end
      it "renders the first line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution1}
        should have_contestsolution_line(contestsolution1.id, "table-ld-success", star_icon, "Solution officielle", "-")
      end
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-danger", x_icon, "Solution officielle", "-")
      end
    end
    
    context "and solution has a star" do
      before do
        contestsolution1.update(:corrected => true, :score => 7, :star => true)
        contestsolution2.update(:corrected => true, :score => 7, :star => true)
      end
      it "renders the first line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution1}
        should have_contestsolution_line(contestsolution1.id, "table-ld-success", star_icon, user.name, 7)
      end
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-success", star_icon, user.name, 7)
      end
    end
    
    context "and solution is correct without star" do
      before do
        contestsolution1.update(:corrected => true, :score => 7)
        contestsolution2.update(:corrected => true, :score => 7)
      end
      it "renders the first line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution1}
        should have_contestsolution_line(contestsolution1.id, "table-ld-success", v_icon, user.name, 7)
      end
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-success", v_icon, user.name, 7)
      end
    end
    
    context "and solution is incorrect" do
      before do
        contestsolution1.update(:corrected => true, :score => 3)
        contestsolution2.update(:corrected => true, :score => 3)
      end
      it "renders the first line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution1}
        should have_contestsolution_line(contestsolution1.id, "table-ld-danger", x_icon, user.name, 3)
      end
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-danger", x_icon, user.name, 3)
      end
    end
    
    context "and solution is not definitely corrected yet" do
      before { contestsolution2.update(:corrected => false, :score => 3) }
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-warning", dash_icon, user.name, 3)
      end
      
      context "and was reserved by him" do
        before { contestsolution2.update(:corrected => false, :score => -1, :reservation => organizer.id) }
        it "renders the second line correctly" do
          render partial: "contestsolutions/line", locals: {sol: contestsolution2}
          should have_contestsolution_line(contestsolution2.id, "table-ld-warning-greener", dash_icon, user.name, "-")
        end
      end
      
      context "and was reserved by someone else" do
        before { contestsolution2.update(:corrected => false, :score => 2, :reservation => organizer.id + 1) }
        it "renders the second line correctly" do
          render partial: "contestsolutions/line", locals: {sol: contestsolution2}
          should have_contestsolution_line(contestsolution2.id, "table-ld-warning-reder", dash_icon, user.name, "2")
        end
      end
    end
  end
  
  context "if user is a student" do
    before { sign_in_view(user) }
    
    context "and solution has a star" do
      before do
        contestsolution1.update(:corrected => true, :score => 7, :star => true)
        contestsolution2.update(:corrected => true, :score => 7, :star => true)
      end
      it "renders the first line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution1}
        should have_contestsolution_line(contestsolution1.id, "table-ld-success", star_icon, user.name, 7)
      end
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-warning", dash_icon, user.name, "-")
      end
    end
    
    context "and solution is correct without star" do
      before do
        contestsolution1.update(:corrected => true, :score => 7)
        contestsolution2.update(:corrected => true, :score => 7)
      end
      it "renders the first line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution1}
        should have_contestsolution_line(contestsolution1.id, "table-ld-success", v_icon, user.name, 7)
      end
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-warning", dash_icon, user.name, "-")
      end
    end
    
    context "and solution is incorrect" do
      before do
        contestsolution1.update(:corrected => true, :score => 3)
        contestsolution2.update(:corrected => true, :score => 3)
      end
      it "renders the first line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution1}
        should have_contestsolution_line(contestsolution1.id, "table-ld-danger", x_icon, user.name, 3)
      end
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-warning", dash_icon, user.name, "-")
      end
    end
    
    context "and solution is not definitely corrected yet" do
      before { contestsolution2.update(:corrected => false, :score => 3, :reservation => organizer.id) }
      it "renders the second line correctly" do
        render partial: "contestsolutions/line", locals: {sol: contestsolution2}
        should have_contestsolution_line(contestsolution2.id, "table-ld-warning", dash_icon, user.name, "-")
      end
    end
  end
end
