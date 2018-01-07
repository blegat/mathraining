# == Schema Information
#
# Table name: prerequisites
#
#  id              :integer          not null, primary key
#  prerequisite_id :integer
#  chapter_id      :integer
#

require "spec_helper"

describe Prerequisite do

  before { @pre = FactoryGirl.build(:prerequisite) }

  subject { @pre }

  it { should respond_to(:prerequisite) }
  it { should respond_to(:chapter) }

  it { should be_valid }

  # Chapter
  describe "when chapter is not present" do
    before { @pre.chapter = nil }
    it { should_not be_valid }
  end

  # Prerequisite
  describe "when prerequisite is not present" do
    before { @pre.prerequisite = nil }
    it { should_not be_valid }
  end
  describe "when (prerequisite, chapter) already exists" do
    before do
      other_pre = Prerequisite.new
      other_pre.chapter = @pre.chapter
      other_pre.prerequisite = @pre.prerequisite
      other_pre.save
    end
    it { should_not be_valid }
  end

  # Prerequisite
  let(:a) { @pre.chapter }
  let(:b) { @pre.prerequisite }
  let(:c) { FactoryGirl.create(:chapter) }
  let(:d) { FactoryGirl.create(:chapter) }
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

  describe "when there seems to create a redundance (start)" do
    # a->b->c
    # \_d__/
    before do
      a.prerequisites << d
      b.prerequisites << c
      d.prerequisites << c
    end
    it { should be_valid }
  end

  describe "when there seems to create a redundance (start)" do
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
