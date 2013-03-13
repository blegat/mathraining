# == Schema Information
#
# Table name: theories
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  chapter_id :integer
#  order      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Theory do
  pending "add some examples to (or delete) #{__FILE__}"
end
