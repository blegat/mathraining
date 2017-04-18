class DropOldFileTables < ActiveRecord::Migration[5.0]
  def change
  	drop_table :submissionfiles
  	drop_table :correctionfiles
  	drop_table :subjectfiles
  	drop_table :messagefiles
  	drop_table :tchatmessagefiles
  	drop_table :fakesubmissionfiles
  	drop_table :fakecorrectionfiles
  	drop_table :fakesubjectfiles
  	drop_table :fakemessagefiles
  	drop_table :faketchatmessagefiles
  end
end
