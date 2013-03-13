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

ActiveRecord::Schema.define(:version => 20130313212337) do

  create_table "chapters", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "level"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "chapters_sections", :id => false, :force => true do |t|
    t.integer "chapter_id"
    t.integer "section_id"
  end

  create_table "exercises", :force => true do |t|
    t.text     "statement"
    t.boolean  "decimal",    :default => false
    t.float    "answer"
    t.integer  "chapter_id"
    t.integer  "position"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "prerequisites", :force => true do |t|
    t.integer "prerequisite_id"
    t.integer "chapter_id"
  end

  create_table "qcms", :force => true do |t|
    t.text     "statement"
    t.boolean  "many_answers"
    t.integer  "chapter_id"
    t.integer  "position"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

# Could not dump table "sections" because of following StandardError
#   Unknown type 'bool' for column 'fondations'

  create_table "theories", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "chapter_id"
    t.integer  "position"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
