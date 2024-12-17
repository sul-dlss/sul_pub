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

ActiveRecord::Schema[7.0].define(version: 2022_07_18_164661) do
  create_table "author_identities", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "first_name", limit: 255, null: false
    t.string "middle_name", limit: 255
    t.string "last_name", limit: 255, null: false
    t.string "email", limit: 255
    t.string "institution", limit: 255
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["author_id"], name: "index_author_identities_on_author_id"
  end

  create_table "authors", force: :cascade do |t|
    t.integer "cap_profile_id", limit: 4
    t.boolean "active_in_cap"
    t.string "sunetid", limit: 255
    t.integer "university_id", limit: 4
    t.string "email", limit: 255
    t.string "cap_first_name", limit: 255
    t.string "cap_last_name", limit: 255
    t.string "cap_middle_name", limit: 255
    t.string "official_first_name", limit: 255
    t.string "official_last_name", limit: 255
    t.string "official_middle_name", limit: 255
    t.string "preferred_first_name", limit: 255
    t.string "preferred_last_name", limit: 255
    t.string "preferred_middle_name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "california_physician_license", limit: 255
    t.boolean "cap_import_enabled"
    t.string "emails_for_harvest", limit: 255
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

  create_table "batch_uploaded_source_records", force: :cascade do |t|
    t.string "sunet_id", limit: 255
    t.integer "author_id", limit: 4
    t.integer "cap_profile_id", limit: 4
    t.boolean "successful_import"
    t.text "bibtex_source_data", limit: 16777215
    t.string "source_fingerprint", limit: 255
    t.boolean "is_active"
    t.text "title", limit: 65535
    t.integer "year", limit: 4
    t.string "batch_name", limit: 255
    t.text "error_message", limit: 16777215
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "publication_id", limit: 4
    t.index ["author_id"], name: "index_batch_uploaded_source_records_on_author_id"
    t.index ["batch_name"], name: "index_batch_uploaded_source_records_on_batch_name"
    t.index ["cap_profile_id"], name: "index_batch_uploaded_source_records_on_cap_profile_id"
    t.index ["sunet_id"], name: "index_batch_uploaded_source_records_on_sunet_id"
    t.index ["title"], name: "index_batch_uploaded_source_records_on_title"
  end

  create_table "contributions", force: :cascade do |t|
    t.integer "author_id", limit: 4, null: false
    t.integer "cap_profile_id", limit: 4
    t.integer "publication_id", limit: 4, null: false
    t.string "status", limit: 255
    t.boolean "featured"
    t.string "visibility", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "orcid_put_code"
    t.index ["author_id"], name: "index_contributions_on_author_id"
    t.index ["cap_profile_id"], name: "index_contributions_on_cap_profile_id"
    t.index ["orcid_put_code"], name: "index_contributions_on_orcid_put_code"
    t.index ["publication_id", "author_id"], name: "index_contributions_on_publication_id_and_author_id"
    t.index ["publication_id"], name: "index_contributions_on_publication_id"
  end

  create_table "orcid_source_records", force: :cascade do |t|
    t.text "source_data", limit: 16777215
    t.integer "last_modified_date"
    t.string "orcidid"
    t.string "put_code"
    t.string "source_fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "publication_id"
    t.index ["orcidid", "put_code"], name: "index_orcid_source_records_on_orcidid_and_put_code", unique: true
    t.index ["publication_id"], name: "index_orcid_source_records_on_publication_id", unique: true
  end

  create_table "publication_identifiers", force: :cascade do |t|
    t.integer "publication_id", limit: 4
    t.string "identifier_type", limit: 255
    t.string "identifier_value", limit: 255
    t.string "identifier_uri", limit: 255
    t.string "certainty", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["identifier_type", "identifier_value"], name: "pub_identifier_index_by_type_and_value"
    t.index ["identifier_type", "publication_id"], name: "pub_identifier_index_by_pub_and_type"
    t.index ["identifier_type"], name: "index_publication_identifiers_on_identifier_type"
    t.index ["publication_id", "identifier_type"], name: "pub_identifier_index_by_type_and_pub"
    t.index ["publication_id"], name: "index_publication_identifiers_on_publication_id"
  end

  create_table "publications", force: :cascade do |t|
    t.integer "same_as_publications_id", limit: 4
    t.boolean "active"
    t.boolean "deleted"
    t.text "title", limit: 65535
    t.integer "year", limit: 4
    t.integer "lock_version", limit: 4
    t.text "pub_hash", limit: 16777215
    t.integer "pmid", limit: 4
    t.integer "sciencewire_id", limit: 4
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "pages", limit: 255
    t.string "issn", limit: 255
    t.string "publication_type", limit: 255
    t.string "wos_uid"
    t.string "provenance"
    t.index ["issn"], name: "index_publications_on_issn"
    t.index ["pages"], name: "index_publications_on_pages"
    t.index ["pmid"], name: "index_publications_on_pmid"
    t.index ["provenance"], name: "index_publications_on_provenance"
    t.index ["sciencewire_id"], name: "index_publications_on_sciencewire_id"
    t.index ["title"], name: "index_publications_on_title"
    t.index ["updated_at"], name: "index_publications_on_updated_at"
    t.index ["wos_uid"], name: "index_publications_on_wos_uid", unique: true
    t.index ["year"], name: "index_publications_on_year"
  end

  create_table "pubmed_source_records", force: :cascade do |t|
    t.text "source_data", limit: 16777215
    t.integer "pmid", limit: 4
    t.integer "lock_version", limit: 4
    t.string "source_fingerprint", limit: 255
    t.boolean "is_active"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["pmid"], name: "index_pubmed_source_records_on_pmid"
  end

  create_table "sciencewire_source_records", force: :cascade do |t|
    t.text "source_data", limit: 16777215
    t.integer "pmid", limit: 4
    t.integer "sciencewire_id", limit: 4
    t.integer "lock_version", limit: 4
    t.string "source_fingerprint", limit: 255
    t.boolean "is_active"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["pmid"], name: "index_sciencewire_source_records_on_pmid"
    t.index ["sciencewire_id"], name: "index_sciencewire_source_records_on_sciencewire_id"
  end

  create_table "user_submitted_source_records", force: :cascade do |t|
    t.text "source_data", limit: 16777215
    t.integer "pmid", limit: 4
    t.integer "lock_version", limit: 4
    t.string "source_fingerprint", limit: 255
    t.text "title", limit: 65535
    t.integer "year", limit: 4
    t.boolean "is_active"
    t.integer "publication_id", limit: 4
    t.integer "author_id", limit: 4
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["source_fingerprint"], name: "index_user_submitted_source_records_on_source_fingerprint", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", limit: 255, null: false
    t.integer "item_id", limit: 4, null: false
    t.string "event", limit: 255, null: false
    t.string "whodunnit", limit: 255
    t.text "object", limit: 16777215
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "web_of_science_source_records", force: :cascade do |t|
    t.boolean "active"
    t.string "database"
    t.text "source_data"
    t.string "source_fingerprint"
    t.string "uid"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
