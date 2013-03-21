require 'spec_helper'

describe ProblemSubmission do
  before { @p = FactoryGirl.build(:problem_submission) }

  subject { @p }

  it { should be_valid }

end
