# == Schema Information
#
# Table name: questions
#
#  id               :integer          not null, primary key
#  statement        :text
#  is_qcm           :boolean
#  decimal          :boolean          default(FALSE)
#  answer           :float
#  many_answers     :boolean          default(FALSE)
#  chapter_id       :integer
#  position         :integer
#  online           :boolean          default(FALSE)
#  explanation      :text
#  level            :integer          default(1)
#  nb_first_guesses :integer          default(0)
#  nb_correct       :integer          default(0)
#  nb_wrong         :integer          default(0)
#
require "spec_helper"

describe Question, question: true do

  let!(:question) { FactoryGirl.build(:question) }

  subject { question }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { question.statement = " " }
    it { should_not be_valid }
  end
  describe "when statement is too long" do
    before { question.statement = "a" * 16001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { question.position = nil }
    it { should_not be_valid }
  end
  describe "when position is negative" do
    before { question.position = -1 }
    it { should_not be_valid }
  end

  # Answer
  describe "when answer is not present" do
    before { question.answer = nil }
    it { should_not be_valid }
  end

  # Explanation
  describe "when explication is not present" do
    before { question.explanation = nil }
    it { should_not be_valid }
  end

  # Level
  describe "when level is > 4" do
    before { question.level = 5 }
    it { should_not be_valid }
  end
  describe "when level is 4" do
    before { question.level = 4 }
    it { should be_valid }
  end
  
  # Value
  describe "value" do
    before { question.level = 3 }
    specify { expect(question.value).to eq(question.level * 3) }
  end
  
  # check_answer
  describe "check_answer" do
    describe "of integer exercise" do
      let!(:exercise) { FactoryGirl.create(:exercise, answer: 42000) }
      let(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: exercise, guess: 43000) }
      specify do
        expect(exercise.check_answer(nil, {:ans => "42000"})).to eq(["correct", nil])
        expect(exercise.check_answer(nil, {:ans => "42 000"})).to eq(["correct", nil])
        expect(exercise.check_answer(nil, {:ans => "49000"})).to eq(["wrong", 49000])
        expect(exercise.check_answer(nil, {:ans => "49 000"})).to eq(["wrong", 49000])
        expect(exercise.check_answer(nil, {:ans => "42.7"})).to eq(["skip", "La réponse attendue est un nombre entier."])
        expect(exercise.check_answer(nil, {:ans => "1234567890"})).to eq(["skip", "Votre réponse est trop grande (en valeur absolue)."])
        expect(exercise.check_answer(nil, {:ans => ""})).to eq(["skip", "Votre réponse est vide."])
        expect(exercise.check_answer(unsolvedquestion, {:ans => "42000"})).to eq(["correct", nil])
        expect(exercise.check_answer(unsolvedquestion, {:ans => "-42000"})).to eq(["wrong", -42000])
        expect(exercise.check_answer(unsolvedquestion, {:ans => "43000"})).to eq(["skip", "Cette réponse est la même que votre réponse précédente."])
      end
    end
    
    describe "of decimal exercise" do
      let!(:exercise) { FactoryGirl.create(:exercise_decimal, answer: 1.234) }
      let(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: exercise, guess: 2.345) }
      specify do
        expect(exercise.check_answer(nil, {:ans => "1.234"})).to eq(["correct", nil])
        expect(exercise.check_answer(nil, {:ans => "1,2342"})).to eq(["correct", nil])
        expect(exercise.check_answer(nil, {:ans => "1, 2338"})).to eq(["correct", nil])
        expect(exercise.check_answer(nil, {:ans => "1.236"})).to eq(["wrong", 1.236])
        expect(exercise.check_answer(nil, {:ans => "1, 232"})).to eq(["wrong", 1.232])
        expect(exercise.check_answer(nil, {:ans => "La réponse est 1.234"})).to eq(["skip", "La réponse attendue est un nombre réel."])
        expect(exercise.check_answer(nil, {:ans => "-1234567890"})).to eq(["skip", "Votre réponse est trop grande (en valeur absolue)."])
        expect(exercise.check_answer(nil, {:ans => " "})).to eq(["skip", "Votre réponse est vide."])
        expect(exercise.check_answer(unsolvedquestion, {:ans => "1.2341"})).to eq(["correct", nil])
        expect(exercise.check_answer(unsolvedquestion, {:ans => "-1.234"})).to eq(["wrong", -1.234])
        expect(exercise.check_answer(unsolvedquestion, {:ans => "2.345"})).to eq(["skip", "Cette réponse est la même que votre réponse précédente."])
      end
    end
    
    describe "of qcm with single answer" do
      let!(:qcm) { FactoryGirl.create(:qcm) }
      let!(:item1) { FactoryGirl.create(:item, question: qcm, ok: false) }
      let!(:item2) { FactoryGirl.create(:item, question: qcm, ok: true) }
      let!(:item3) { FactoryGirl.create(:item, question: qcm, ok: false) }
      let!(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: qcm, guess: 0) }
      before { unsolvedquestion.items << item1 }
      specify do
        expect(qcm.check_answer(nil, {:ans => {item2.id.to_s => "1"}})).to eq(["correct", nil])
        expect(qcm.check_answer(nil, {:ans => {item3.id.to_s => "1"}})).to eq(["wrong", [item3]])
        expect(qcm.check_answer(nil, {:ans => {item1.id.to_s => "1", item2.id.to_s => "1"}})).to eq(["skip", "Veuillez cocher une réponse."]) # Hack
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item2.id.to_s => "1"}})).to eq(["correct", nil])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item3.id.to_s => "1"}})).to eq(["wrong", [item3]])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item1.id.to_s => "1"}})).to eq(["skip", "Cette réponse est la même que votre réponse précédente."])
      end
    end
    
    describe "of qcm with multiple answers" do
      let!(:qcm) { FactoryGirl.create(:qcm_multiple) }
      let!(:item1) { FactoryGirl.create(:item, question: qcm, ok: false) }
      let!(:item2) { FactoryGirl.create(:item, question: qcm, ok: true) }
      let!(:item3) { FactoryGirl.create(:item, question: qcm, ok: false) }
      let!(:item4) { FactoryGirl.create(:item, question: qcm, ok: true) }
      let!(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: qcm, guess: 0) }
      let!(:unsolvedquestion_empty) { FactoryGirl.create(:unsolvedquestion, question: qcm, guess: 0) }
      before do
        unsolvedquestion.items << item2
        unsolvedquestion.items << item3
      end
      specify do
        expect(qcm.check_answer(nil, {:ans => {item2.id.to_s => "1", item4.id.to_s => "1"}})).to eq(["correct", nil])
        expect(qcm.check_answer(nil, {:ans => {item2.id.to_s => "1"}})).to eq(["wrong", [item2]])
        expect(qcm.check_answer(nil, {:ans => {item1.id.to_s => "1", item2.id.to_s => "1", item4.id.to_s => "1"}})).to eq(["wrong", [item1, item2, item4]])
        expect(qcm.check_answer(nil, {:ans => {}})).to eq(["wrong", []])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item2.id.to_s => "1", item4.id.to_s => "1"}})).to eq(["correct", nil])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item2.id.to_s => "1"}})).to eq(["wrong", [item2]])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item2.id.to_s => "1", item3.id.to_s => "1", item4.id.to_s => "1"}})).to eq(["wrong", [item2, item3, item4]])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {}})).to eq(["wrong", []])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item2.id.to_s => "1", item3.id.to_s => "1"}})).to eq(["skip", "Cette réponse est la même que votre réponse précédente."])
        expect(qcm.check_answer(unsolvedquestion_empty, {:ans => {item1.id.to_s => "1"}})).to eq(["wrong", [item1]])
        expect(qcm.check_answer(unsolvedquestion_empty, {:ans => {}})).to eq(["skip", "Cette réponse est la même que votre réponse précédente."])
      end
    end
    
    describe "of qcm with all answers wrong" do
      let!(:qcm) { FactoryGirl.create(:qcm_multiple) }
      let!(:item1) { FactoryGirl.create(:item, question: qcm, ok: false) }
      let!(:item2) { FactoryGirl.create(:item, question: qcm, ok: false) }
      let!(:item3) { FactoryGirl.create(:item, question: qcm, ok: false) }
      let!(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: qcm, guess: 0) }
      before do
        unsolvedquestion.items << item1
      end
      specify do
        expect(qcm.check_answer(nil, {:ans => {}})).to eq(["correct", nil])
        expect(qcm.check_answer(nil, {:ans => {item2.id.to_s => "1"}})).to eq(["wrong", [item2]])
        expect(qcm.check_answer(nil, {:ans => {item1.id.to_s => "1", item2.id.to_s => "1", item3.id.to_s => "1"}})).to eq(["wrong", [item1, item2, item3]])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {}})).to eq(["correct", nil])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item3.id.to_s => "1"}})).to eq(["wrong", [item3]])
        expect(qcm.check_answer(unsolvedquestion, {:ans => {item1.id.to_s => "1"}})).to eq(["skip", "Cette réponse est la même que votre réponse précédente."])
      end
    end
  end
end
