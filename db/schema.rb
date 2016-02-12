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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160212043208) do

  create_table "authors", force: :cascade do |t|
    t.integer  "cap_profile_id",               limit: 4
    t.boolean  "active_in_cap"
    t.string   "sunetid",                      limit: 255
    t.integer  "university_id",                limit: 4
    t.string   "email",                        limit: 255
    t.string   "cap_first_name",               limit: 255
    t.string   "cap_last_name",                limit: 255
    t.string   "cap_middle_name",              limit: 255
    t.string   "official_first_name",          limit: 255
    t.string   "official_last_name",           limit: 255
    t.string   "official_middle_name",         limit: 255
    t.string   "preferred_first_name",         limit: 255
    t.string   "preferred_last_name",          limit: 255
    t.string   "preferred_middle_name",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "california_physician_license", limit: 255
    t.boolean  "cap_import_enabled"
    t.string   "emails_for_harvest",           limit: 255
  end

  add_index "authors", ["active_in_cap"], name: "index_authors_on_active_in_cap", using: :btree
  add_index "authors", ["california_physician_license"], name: "index_authors_on_california_physician_license", using: :btree
  add_index "authors", ["cap_profile_id"], name: "index_authors_on_cap_profile_id", using: :btree
  add_index "authors", ["sunetid"], name: "index_authors_on_sunetid", using: :btree
  add_index "authors", ["university_id"], name: "index_authors_on_university_id", using: :btree

  create_table "batch_uploaded_source_records", force: :cascade do |t|
    t.string   "sunet_id",           limit: 255
    t.integer  "author_id",          limit: 4
    t.integer  "cap_profile_id",     limit: 4
    t.boolean  "successful_import"
    t.text     "bibtex_source_data", limit: 65535
    t.string   "source_fingerprint", limit: 255
    t.boolean  "is_active"
    t.text     "title",              limit: 65535
    t.integer  "year",               limit: 4
    t.string   "batch_name",         limit: 255
    t.text     "error_message",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publication_id",     limit: 4
  end

  add_index "batch_uploaded_source_records", ["author_id"], name: "index_batch_uploaded_source_records_on_author_id", using: :btree
  add_index "batch_uploaded_source_records", ["batch_name"], name: "index_batch_uploaded_source_records_on_batch_name", using: :btree
  add_index "batch_uploaded_source_records", ["cap_profile_id"], name: "index_batch_uploaded_source_records_on_cap_profile_id", using: :btree
  add_index "batch_uploaded_source_records", ["sunet_id"], name: "index_batch_uploaded_source_records_on_sunet_id", using: :btree
  add_index "batch_uploaded_source_records", ["title"], name: "index_batch_uploaded_source_records_on_title", length: {"title"=>255}, using: :btree

  create_table "contributions", force: :cascade do |t|
    t.integer  "author_id",      limit: 4
    t.integer  "cap_profile_id", limit: 4
    t.integer  "publication_id", limit: 4
    t.string   "status",         limit: 255
    t.boolean  "featured"
    t.string   "visibility",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contributions", ["author_id"], name: "index_contributions_on_author_id", using: :btree
  add_index "contributions", ["cap_profile_id"], name: "index_contributions_on_cap_profile_id", using: :btree
  add_index "contributions", ["publication_id", "author_id"], name: "index_contributions_on_publication_id_and_author_id", using: :btree
  add_index "contributions", ["publication_id"], name: "index_contributions_on_publication_id", using: :btree

  create_table "publication_identifiers", force: :cascade do |t|
    t.integer  "publication_id",   limit: 4
    t.string   "identifier_type",  limit: 255
    t.string   "identifier_value", limit: 255
    t.string   "identifier_uri",   limit: 255
    t.string   "certainty",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "publication_identifiers", ["identifier_type", "identifier_value"], name: "pub_identifier_index_by_type_and_value", using: :btree
  add_index "publication_identifiers", ["identifier_type", "publication_id"], name: "pub_identifier_index_by_pub_and_type", using: :btree
  add_index "publication_identifiers", ["identifier_type"], name: "index_publication_identifiers_on_identifier_type", using: :btree
  add_index "publication_identifiers", ["publication_id", "identifier_type"], name: "pub_identifier_index_by_type_and_pub", using: :btree
  add_index "publication_identifiers", ["publication_id"], name: "index_publication_identifiers_on_publication_id", using: :btree

  create_table "publications", force: :cascade do |t|
    t.integer  "same_as_publications_id", limit: 4
    t.boolean  "active"
    t.boolean  "deleted"
    t.text     "title",                   limit: 65535
    t.integer  "year",                    limit: 4
    t.integer  "lock_version",            limit: 4
    t.text     "xml",                     limit: 65535
    t.text     "pub_hash",                limit: 16777215
    t.integer  "pmid",                    limit: 4
    t.integer  "sciencewire_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pages",                   limit: 255
    t.string   "issn",                    limit: 255
    t.string   "publication_type",        limit: 255
  end

  add_index "publications", ["issn"], name: "index_publications_on_issn", using: :btree
  add_index "publications", ["pages"], name: "index_publications_on_pages", using: :btree
  add_index "publications", ["pmid"], name: "index_publications_on_pmid", using: :btree
  add_index "publications", ["sciencewire_id"], name: "index_publications_on_sciencewire_id", using: :btree
  add_index "publications", ["title"], name: "index_publications_on_title", length: {"title"=>255}, using: :btree
  add_index "publications", ["updated_at"], name: "index_publications_on_updated_at", using: :btree
  add_index "publications", ["year"], name: "index_publications_on_year", using: :btree

  create_table "pubmed_source_records", force: :cascade do |t|
    t.text     "source_data",        limit: 65535
    t.integer  "pmid",               limit: 4
    t.integer  "lock_version",       limit: 4
    t.string   "source_fingerprint", limit: 255
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pubmed_source_records", ["pmid"], name: "index_pubmed_source_records_on_pmid", using: :btree

  create_table "sciencewire_source_records", force: :cascade do |t|
    t.text     "source_data",        limit: 65535
    t.integer  "pmid",               limit: 4
    t.integer  "sciencewire_id",     limit: 4
    t.integer  "lock_version",       limit: 4
    t.string   "source_fingerprint", limit: 255
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sciencewire_source_records", ["pmid"], name: "index_sciencewire_source_records_on_pmid", using: :btree
  add_index "sciencewire_source_records", ["sciencewire_id"], name: "index_sciencewire_source_records_on_sciencewire_id", using: :btree

  create_table "user_submitted_source_records", force: :cascade do |t|
    t.text     "source_data",        limit: 65535
    t.integer  "pmid",               limit: 4
    t.integer  "lock_version",       limit: 4
    t.string   "source_fingerprint", limit: 255
    t.text     "title",              limit: 65535
    t.integer  "year",               limit: 4
    t.boolean  "is_active"
    t.integer  "publication_id",     limit: 4
    t.integer  "author_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_submitted_source_records", ["source_fingerprint"], name: "index_user_submitted_source_records_on_source_fingerprint", unique: true, using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255,   null: false
    t.integer  "item_id",    limit: 4,     null: false
    t.string   "event",      limit: 255,   null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 65535
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
