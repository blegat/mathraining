# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130912125011) do

  create_table "actualities", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "chapters", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "level"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "online",      :default => false
  end

  create_table "chapters_sections", :id => false, :force => true do |t|
    t.integer "chapter_id"
    t.integer "section_id"
  end

  create_table "chapters_users", :id => false, :force => true do |t|
    t.integer "chapter_id"
    t.integer "user_id"
  end

  create_table "choices", :force => true do |t|
    t.string   "ans"
    t.boolean  "ok",         :default => false
    t.integer  "qcm_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "choices", ["qcm_id"], :name => "index_choices_on_qcm_id"

  create_table "choices_solvedqcms", :id => false, :force => true do |t|
    t.integer "choice_id"
    t.integer "solvedqcm_id"
  end

  add_index "choices_solvedqcms", ["solvedqcm_id"], :name => "index_choices_solvedqcms_on_solvedqcm_id"

  create_table "correctionfiles", :force => true do |t|
    t.integer  "correction_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  add_index "correctionfiles", ["correction_id"], :name => "index_correctionfiles_on_correction_id"

  create_table "corrections", :force => true do |t|
    t.integer  "user_id"
    t.integer  "submission_id"
    t.text     "content"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "corrections", ["submission_id"], :name => "index_corrections_on_submission_id"

  create_table "exercises", :force => true do |t|
    t.text     "statement"
    t.boolean  "decimal",     :default => false
    t.float    "answer"
    t.integer  "chapter_id"
    t.integer  "position"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "online",      :default => false
    t.text     "explanation"
  end

  create_table "followings", :force => true do |t|
    t.integer  "submission_id"
    t.integer  "user_id"
    t.boolean  "read"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "followings", ["submission_id", "user_id"], :name => "index_followings_on_submission_id_and_user_id"

  create_table "messagefiles", :force => true do |t|
    t.integer  "message_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  add_index "messagefiles", ["message_id"], :name => "index_messagefiles_on_message_id"

  create_table "messages", :force => true do |t|
    t.text     "content"
    t.integer  "subject_id"
    t.integer  "user_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "admin_user", :default => false
  end

  add_index "messages", ["subject_id"], :name => "index_messages_on_subject_id"

  create_table "notifs", :force => true do |t|
    t.integer  "submission_id"
    t.integer  "user_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "notifs", ["user_id"], :name => "index_notifs_on_user_id"

  create_table "pictures", :force => true do |t|
    t.integer  "user_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "pictures", ["user_id"], :name => "index_pictures_on_user_id"

  create_table "points", :force => true do |t|
    t.integer "user_id"
    t.integer "rating"
  end

  add_index "points", ["user_id"], :name => "index_points_on_user_id"

  create_table "pointspersections", :force => true do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "points"
  end

  add_index "pointspersections", ["user_id"], :name => "index_pointspersections_on_user_id"

  create_table "prerequisites", :force => true do |t|
    t.integer "prerequisite_id"
    t.integer "chapter_id"
  end

  create_table "problems", :force => true do |t|
    t.string   "name"
    t.text     "statement"
    t.integer  "chapter_id"
    t.integer  "position"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "online",      :default => false
    t.integer  "level"
    t.text     "explanation", :default => ""
  end

  create_table "qcms", :force => true do |t|
    t.text     "statement"
    t.boolean  "many_answers"
    t.integer  "chapter_id"
    t.integer  "position"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "online",       :default => false
    t.text     "explanation"
  end

  create_table "sections", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "image"
  end

  create_table "solvedexercises", :force => true do |t|
    t.integer  "user_id"
    t.integer  "exercise_id"
    t.float    "guess"
    t.boolean  "correct"
    t.integer  "nb_guess"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "solvedexercises", ["user_id"], :name => "index_solvedexercises_on_user_id"

  create_table "solvedproblems", :force => true do |t|
    t.integer  "problem_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "solvedqcms", :force => true do |t|
    t.integer  "user_id"
    t.integer  "qcm_id"
    t.boolean  "correct"
    t.integer  "nb_guess"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "solvedqcms", ["user_id"], :name => "index_solvedqcms_on_user_id"

  create_table "subjectfiles", :force => true do |t|
    t.integer  "subject_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  add_index "subjectfiles", ["subject_id"], :name => "index_subjectfiles_on_subject_id"

  create_table "subjects", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "user_id"
    t.integer  "chapter_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.datetime "lastcomment"
    t.boolean  "admin",       :default => false
    t.boolean  "admin_user",  :default => false
    t.boolean  "important",   :default => false
  end

  add_index "subjects", ["chapter_id"], :name => "index_subjects_on_chapter_id"

  create_table "submissionfiles", :force => true do |t|
    t.integer  "submission_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  add_index "submissionfiles", ["submission_id"], :name => "index_submissionfiles_on_submission_id"

  create_table "submissions", :force => true do |t|
    t.integer  "problem_id"
    t.integer  "user_id"
    t.text     "content"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "status",     :default => 0
  end

  add_index "submissions", ["problem_id", "user_id"], :name => "index_submissions_on_problem_id_and_user_id"

  create_table "theories", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "chapter_id"
    t.integer  "position"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "online",     :default => false
  end

  create_table "theories_users", :id => false, :force => true do |t|
    t.integer "theory_id"
    t.integer "user_id"
  end

  add_index "theories_users", ["user_id"], :name => "index_theories_users_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           :default => false
    t.boolean  "root",            :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "key"
    t.boolean  "email_confirm",   :default => true
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
