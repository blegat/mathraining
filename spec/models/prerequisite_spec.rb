# == Schema Information
#
# Table name: prerequisites
#
#  id              :integer          not null, primary key
#  prerequisite_id :integer
#  chapter_id      :integer
#
require "spec_helper"

describe Prerequisite, prerequisite: true do

  let!(:chap1) { FactoryBot.create(:chapter) }
  let!(:chap2) { FactoryBot.create(:chapter) }
  let!(:pre) { FactoryBot.build(:prerequisite, chapter: chap1, prerequisite: chap2) }

  subject { pre }

  it { should be_valid }

  # Chapter
  describe "when chapter is not present" do
    before { pre.chapter = nil }
    it { should_not be_valid }
  end

  # Prerequisite
  describe "when prerequisite is not present" do
    before { pre.prerequisite = nil }
    it { should_not be_valid }
  end
  
  # Avoid duplicates
  describe "when (prerequisite, chapter) already exists" do
    before { other_pre = FactoryBot.create(:prerequisite, chapter: chap1, prerequisite: chap2) }
    it { should_not be_valid }
  end

  # Graph checks
  let(:a) { pre.chapter }
  let(:b) { pre.prerequisite }
  let(:c) { FactoryBot.create(:chapter) }
  let(:d) { FactoryBot.create(:chapter) }
  let(:e) { FactoryBot.create(:chapter) }
  let(:f) { FactoryBot.create(:chapter) }
  let(:g) { FactoryBot.create(:chapter) }
  let(:h) { FactoryBot.create(:chapter) }
  let(:i) { FactoryBot.create(:chapter) }
  let(:j) { FactoryBot.create(:chapter) }
  let(:k) { FactoryBot.create(:chapter) }

  describe "when there is a loop" do
    # a->b->c->a
    before do
      b.prerequisites << c
      c.prerequisites << a
    end
    it { should_not be_valid }
  end

  describe "when it is redundant" do
    # a----->b
    #  \->c-/
    before do
      a.prerequisites << c
      c.prerequisites << b
    end
    it { should_not be_valid }
  end

  describe "when it creates redundance (start)" do
    # a->b->c
    # \____/
    before do
      a.prerequisites << c
      b.prerequisites << c
    end
    it { should_not be_valid }
  end

  describe "when it creates redundance (middle)" do
    # d->a->b->c
    # \_______/
    before do
      b.prerequisites << c
      d.prerequisites << a
      d.prerequisites << c
    end
    it { should_not be_valid }
  end

  describe "when it creates redundance (end)" do
    # c->a->b
    # \____/
    before do
      c.prerequisites << a
      c.prerequisites << b
    end
    it { should_not be_valid }
  end

  describe "when it seems to create a redundance (start)" do
    # a->b->c
    # \_d__/
    before do
      a.prerequisites << d
      b.prerequisites << c
      d.prerequisites << c
    end
    it { should be_valid }
  end

  describe "when it seems to create a redundance (end)" do
    # c->a->b
    # \_d__/
    before do
      c.prerequisites << a
      c.prerequisites << d
      d.prerequisites << b
    end
    it { should be_valid }
  end
end
