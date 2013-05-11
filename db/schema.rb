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

ActiveRecord::Schema.define(:version => 20130222202128) do

  create_table "author_identifiers", :force => true do |t|
    t.integer  "author_id"
    t.string   "identifier_type"
    t.string   "identifier_value"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "author_names", :force => true do |t|
    t.integer  "author_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "middle_name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "authors", :force => true do |t|
    t.integer  "cap_profile_id"
    t.string   "sunetid"
    t.integer  "university_id"
    t.integer  "shc_doctor_no"
    t.string   "email"
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
    t.string   "status"
    t.boolean  "featured"
    t.string   "visibility"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "population_memberships", :force => true do |t|
    t.integer  "author_id"
    t.integer  "cap_profile_id"
    t.string   "population_name"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "publication_identifiers", :force => true do |t|
    t.integer  "publication_id"
    t.string   "identifier_type"
    t.string   "identifier_value"
    t.string   "identifier_uri"
    t.string   "certainty"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "publications", :force => true do |t|
    t.integer  "same_as_publications_id"
    t.boolean  "active"
    t.boolean  "deleted"
    t.string   "title"
    t.integer  "year"
    t.integer  "lock_version"
    t.text     "xml"
    t.text     "pub_hash"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "source_records", :force => true do |t|
    t.text     "source_data"
    t.integer  "original_source_id"
    t.integer  "publication_id"
    t.integer  "lock_version"
    t.string   "title"
    t.integer  "year"
    t.string   "source_name"
    t.string   "source_data_type"
    t.boolean  "is_active"
    t.boolean  "is_local_only"
    t.string   "source_fingerprint"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

end
