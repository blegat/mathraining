# == Schema Information
#
# Table name: globalvariables
#
#  id      :bigint           not null, primary key
#  key     :string
#  message :text
#  value   :boolean
#
# Indexes
#
#  index_globalvariables_on_key  (key) UNIQUE
#
require "spec_helper"

describe Globalvariable, globalvariable: true do

  let!(:globalvariable) { Globalvariable.new(:key => "my_key", :value => true, :message => "Warning !") }

  subject { globalvariable }

  it { should be_valid }

  # Key
  describe "when key is not present" do
    before { globalvariable.key = nil }
    it { should_not be_valid }
  end
  
  # Value
  describe "when value is not present" do
    before { globalvariable.value = nil }
    it { should_not be_valid }
  end

end
