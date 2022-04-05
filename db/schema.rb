# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_04_05_041748) do

  create_table "author_identities", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.string "email"
    t.string "institution"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_author_identities_on_author_id"
  end

  create_table "authors", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "cap_profile_id"
    t.boolean "active_in_cap"
    t.string "sunetid"
    t.integer "university_id"
    t.string "email"
    t.string "cap_first_name"
    t.string "cap_last_name"
    t.string "cap_middle_name"
    t.string "official_first_name"
    t.string "official_last_name"
    t.string "official_middle_name"
    t.string "preferred_first_name"
    t.string "preferred_last_name"
    t.string "preferred_middle_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "california_physician_license"
    t.boolean "cap_import_enabled"
    t.string "emails_for_harvest"
    t.string "orcidid"
    t.string "cap_visibility"
    t.bigint "orcid_last_modified"
    t.index ["active_in_cap"], name: "index_authors_on_active_in_cap"
    t.index ["california_physician_license"], name: "index_authors_on_california_physician_license"
    t.index ["cap_profile_id"], name: "index_authors_on_cap_profile_id", unique: true
    t.index ["cap_visibility"], name: "index_authors_on_cap_visibility"
    t.index ["sunetid"], name: "index_authors_on_sunetid"
    t.index ["university_id"], name: "index_authors_on_university_id"
  end

  create_table "batch_uploaded_source_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "sunet_id"
    t.integer "author_id"
    t.integer "cap_profile_id"
    t.boolean "successful_import"
    t.text "bibtex_source_data", size: :medium
    t.string "source_fingerprint"
    t.boolean "is_active"
    t.text "title"
    t.integer "year"
    t.string "batch_name"
    t.text "error_message", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "publication_id"
    t.index ["author_id"], name: "index_batch_uploaded_source_records_on_author_id"
    t.index ["batch_name"], name: "index_batch_uploaded_source_records_on_batch_name"
    t.index ["cap_profile_id"], name: "index_batch_uploaded_source_records_on_cap_profile_id"
    t.index ["sunet_id"], name: "index_batch_uploaded_source_records_on_sunet_id"
    t.index ["title"], name: "index_batch_uploaded_source_records_on_title", length: 255
  end

  create_table "contributions", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "author_id", null: false
    t.integer "cap_profile_id"
    t.integer "publication_id", null: false
    t.string "status"
    t.boolean "featured"
    t.string "visibility"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "orcid_put_code"
    t.index ["author_id"], name: "index_contributions_on_author_id"
    t.index ["cap_profile_id"], name: "index_contributions_on_cap_profile_id"
    t.index ["orcid_put_code"], name: "index_contributions_on_orcid_put_code"
    t.index ["publication_id", "author_id"], name: "index_contributions_on_publication_id_and_author_id"
    t.index ["publication_id"], name: "index_contributions_on_publication_id"
  end

  create_table "orcid_source_records", charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.text "source_data", size: :medium
    t.bigint "last_modified_date"
    t.string "orcidid"
    t.string "put_code"
    t.string "source_fingerprint"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "publication_id"
    t.index ["orcidid", "put_code"], name: "index_orcid_source_records_on_orcidid_and_put_code", unique: true
    t.index ["publication_id"], name: "index_orcid_source_records_on_publication_id", unique: true
  end

  create_table "publication_identifiers", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "publication_id"
    t.string "identifier_type"
    t.string "identifier_value"
    t.string "identifier_uri"
    t.string "certainty"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["identifier_type", "identifier_value"], name: "pub_identifier_index_by_type_and_value"
    t.index ["identifier_type", "publication_id"], name: "pub_identifier_index_by_pub_and_type"
    t.index ["identifier_type"], name: "index_publication_identifiers_on_identifier_type"
    t.index ["publication_id", "identifier_type"], name: "pub_identifier_index_by_type_and_pub"
    t.index ["publication_id"], name: "index_publication_identifiers_on_publication_id"
  end

  create_table "publications", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "same_as_publications_id"
    t.boolean "active"
    t.boolean "deleted"
    t.text "title"
    t.integer "year"
    t.integer "lock_version"
    t.text "pub_hash", size: :medium
    t.integer "pmid"
    t.integer "sciencewire_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "pages"
    t.string "issn"
    t.string "publication_type"
    t.string "wos_uid"
    t.index ["issn"], name: "index_publications_on_issn"
    t.index ["pages"], name: "index_publications_on_pages"
    t.index ["pmid"], name: "index_publications_on_pmid"
    t.index ["sciencewire_id"], name: "index_publications_on_sciencewire_id"
    t.index ["title"], name: "index_publications_on_title", length: 255
    t.index ["updated_at"], name: "index_publications_on_updated_at"
    t.index ["wos_uid"], name: "index_publications_on_wos_uid", unique: true
    t.index ["year"], name: "index_publications_on_year"
  end

  create_table "pubmed_source_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.text "source_data", size: :medium
    t.integer "pmid"
    t.integer "lock_version"
    t.string "source_fingerprint"
    t.boolean "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["pmid"], name: "index_pubmed_source_records_on_pmid"
  end

  create_table "sciencewire_source_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.text "source_data", size: :medium
    t.integer "pmid"
    t.integer "sciencewire_id"
    t.integer "lock_version"
    t.string "source_fingerprint"
    t.boolean "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["pmid"], name: "index_sciencewire_source_records_on_pmid"
    t.index ["sciencewire_id"], name: "index_sciencewire_source_records_on_sciencewire_id"
  end

  create_table "user_submitted_source_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.text "source_data", size: :medium
    t.integer "pmid"
    t.integer "lock_version"
    t.string "source_fingerprint"
    t.text "title"
    t.integer "year"
    t.boolean "is_active"
    t.integer "publication_id"
    t.integer "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["source_fingerprint"], name: "index_user_submitted_source_records_on_source_fingerprint", unique: true
  end

  create_table "versions", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :medium
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "web_of_science_source_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "active"
    t.string "database"
    t.text "source_data", size: :medium
    t.string "source_fingerprint"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "doi"
    t.integer "pmid"
    t.integer "publication_id"
    t.index ["doi"], name: "web_of_science_doi_index"
    t.index ["pmid"], name: "web_of_science_pmid_index"
    t.index ["publication_id"], name: "index_web_of_science_source_records_on_publication_id", unique: true
    t.index ["source_fingerprint"], name: "index_web_of_science_source_records_on_source_fingerprint", unique: true
    t.index ["uid"], name: "index_web_of_science_source_records_on_uid", unique: true
  end

  add_foreign_key "author_identities", "authors"
  add_foreign_key "orcid_source_records", "publications"
  add_foreign_key "web_of_science_source_records", "publications"
end
