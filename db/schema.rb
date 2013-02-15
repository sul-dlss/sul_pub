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

ActiveRecord::Schema.define(:version => 20130206002003) do

  create_table "authors", :force => true do |t|
    t.integer  "cap_profile_id"
    t.string   "sunetid"
    t.integer  "university_id"
    t.integer  "shc_doctor_no"
    t.string   "ca_license_number"
    t.string   "cap_first_name"
    t.string   "cap_last_name"
    t.string   "cap_middle_name"
    t.string   "display_name"
    t.string   "official_first_name"
    t.string   "official_last_name"
    t.string   "official_middle_name"
    t.string   "preferred_first_name"
    t.string   "preferred_last_name"
    t.string   "preferred_middle_name"
    t.string   "pubmed_last_name"
    t.string   "pubmed_first_initial"
    t.string   "pubmed_middle_initial"
    t.string   "pubmed_institution"
    t.string   "pubmed_other_institution"
    t.string   "cap_url"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "contributions", :force => true do |t|
    t.integer  "author_id"
    t.integer  "cap_profile_id"
    t.integer  "publication_id"
    t.string   "confirmed_status"
    t.string   "highlight_ind"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "population_memberships", :force => true do |t|
    t.integer  "author_id"
    t.integer  "cap_profile_id"
    t.string   "population_name"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "publications", :force => true do |t|
    t.integer  "same_as_publications_id"
    t.boolean  "active"
    t.boolean  "deleted"
    t.string   "human_readable_title"
    t.integer  "lock_version"
    t.text     "xml"
    t.text     "json"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

end
