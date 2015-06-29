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

ActiveRecord::Schema.define(version: 20_131_119_221_527) do
  create_table 'authors', force: true do |t|
    t.integer 'cap_profile_id'
    t.boolean 'active_in_cap'
    t.string 'sunetid'
    t.integer 'university_id'
    t.string 'email'
    t.string 'cap_first_name'
    t.string 'cap_last_name'
    t.string 'cap_middle_name'
    t.string 'official_first_name'
    t.string 'official_last_name'
    t.string 'official_middle_name'
    t.string 'preferred_first_name'
    t.string 'preferred_last_name'
    t.string 'preferred_middle_name'
    t.datetime 'created_at',                   null: false
    t.datetime 'updated_at',                   null: false
    t.string 'california_physician_license'
    t.boolean 'cap_import_enabled'
    t.string 'emails_for_harvest'
  end

  add_index 'authors', ['active_in_cap'], name: 'index_authors_on_active_in_cap'
  add_index 'authors', ['california_physician_license'], name: 'index_authors_on_california_physician_license'
  add_index 'authors', ['cap_profile_id'], name: 'index_authors_on_cap_profile_id'
  add_index 'authors', ['sunetid'], name: 'index_authors_on_sunetid'
  add_index 'authors', ['university_id'], name: 'index_authors_on_university_id'

  create_table 'batch_uploaded_source_records', force: true do |t|
    t.string 'sunet_id'
    t.integer 'author_id'
    t.integer 'cap_profile_id'
    t.boolean 'successful_import'
    t.text 'bibtex_source_data'
    t.string 'source_fingerprint'
    t.boolean 'is_active'
    t.string 'title'
    t.integer 'year'
    t.string 'batch_name'
    t.text 'error_message'
    t.datetime 'created_at',         null: false
    t.datetime 'updated_at',         null: false
    t.integer 'publication_id'
  end

  add_index 'batch_uploaded_source_records', ['author_id'], name: 'index_batch_uploaded_source_records_on_author_id'
  add_index 'batch_uploaded_source_records', ['batch_name'], name: 'index_batch_uploaded_source_records_on_batch_name'
  add_index 'batch_uploaded_source_records', ['cap_profile_id'], name: 'index_batch_uploaded_source_records_on_cap_profile_id'
  add_index 'batch_uploaded_source_records', ['sunet_id'], name: 'index_batch_uploaded_source_records_on_sunet_id'
  add_index 'batch_uploaded_source_records', ['title'], name: 'index_batch_uploaded_source_records_on_title'

  create_table 'contributions', force: true do |t|
    t.integer 'author_id'
    t.integer 'cap_profile_id'
    t.integer 'publication_id'
    t.string 'status'
    t.boolean 'featured'
    t.string 'visibility'
    t.datetime 'created_at',     null: false
    t.datetime 'updated_at',     null: false
  end

  add_index 'contributions', ['author_id'], name: 'index_contributions_on_author_id'
  add_index 'contributions', ['cap_profile_id'], name: 'index_contributions_on_cap_profile_id'
  add_index 'contributions', %w(publication_id author_id), name: 'index_contributions_on_publication_id_and_author_id'
  add_index 'contributions', ['publication_id'], name: 'index_contributions_on_publication_id'

  create_table 'publication_identifiers', force: true do |t|
    t.integer 'publication_id'
    t.string 'identifier_type'
    t.string 'identifier_value'
    t.string 'identifier_uri'
    t.string 'certainty'
    t.datetime 'created_at',       null: false
    t.datetime 'updated_at',       null: false
  end

  add_index 'publication_identifiers', %w(identifier_type identifier_value), name: 'pub_identifier_index_by_type_and_value'
  add_index 'publication_identifiers', %w(identifier_type publication_id), name: 'pub_identifier_index_by_pub_and_type'
  add_index 'publication_identifiers', ['identifier_type'], name: 'index_publication_identifiers_on_identifier_type'
  add_index 'publication_identifiers', %w(publication_id identifier_type), name: 'pub_identifier_index_by_type_and_pub'
  add_index 'publication_identifiers', ['publication_id'], name: 'index_publication_identifiers_on_publication_id'

  create_table 'publications', force: true do |t|
    t.integer 'same_as_publications_id'
    t.boolean 'active'
    t.boolean 'deleted'
    t.string 'title'
    t.integer 'year'
    t.integer 'lock_version'
    t.text 'xml'
    t.text 'pub_hash',                limit: 16_777_215
    t.integer 'pmid'
    t.integer 'sciencewire_id'
    t.datetime 'created_at',                                  null: false
    t.datetime 'updated_at',                                  null: false
    t.string 'pages'
    t.string 'issn'
    t.string 'publication_type'
  end

  add_index 'publications', ['issn'], name: 'index_publications_on_issn'
  add_index 'publications', ['pages'], name: 'index_publications_on_pages'
  add_index 'publications', ['pmid'], name: 'index_publications_on_pmid'
  add_index 'publications', ['sciencewire_id'], name: 'index_publications_on_sciencewire_id'
  add_index 'publications', ['title'], name: 'index_publications_on_title'
  add_index 'publications', ['updated_at'], name: 'index_publications_on_updated_at'
  add_index 'publications', ['year'], name: 'index_publications_on_year'

  create_table 'pubmed_source_records', force: true do |t|
    t.text 'source_data'
    t.integer 'pmid'
    t.integer 'lock_version'
    t.string 'source_fingerprint'
    t.boolean 'is_active'
    t.datetime 'created_at',         null: false
    t.datetime 'updated_at',         null: false
  end

  add_index 'pubmed_source_records', ['pmid'], name: 'index_pubmed_source_records_on_pmid'

  create_table 'sciencewire_source_records', force: true do |t|
    t.text 'source_data'
    t.integer 'pmid'
    t.integer 'sciencewire_id'
    t.integer 'lock_version'
    t.string 'source_fingerprint'
    t.boolean 'is_active'
    t.datetime 'created_at',         null: false
    t.datetime 'updated_at',         null: false
  end

  add_index 'sciencewire_source_records', ['pmid'], name: 'index_sciencewire_source_records_on_pmid'
  add_index 'sciencewire_source_records', ['sciencewire_id'], name: 'index_sciencewire_source_records_on_sciencewire_id'

  create_table 'trash_records', force: true do |t|
    t.string 'trashable_type', null: false
    t.integer 'trashable_id',   null: false
    t.binary 'data'
    t.datetime 'created_at'
  end

  add_index 'trash_records', %w(created_at trashable_type), name: 'created_at_type'
  add_index 'trash_records', %w(trashable_type trashable_id), name: 'trashable'

  create_table 'user_submitted_source_records', force: true do |t|
    t.text 'source_data'
    t.integer 'pmid'
    t.integer 'lock_version'
    t.string 'source_fingerprint'
    t.string 'title'
    t.integer 'year'
    t.boolean 'is_active'
    t.integer 'publication_id'
    t.integer 'author_id'
    t.datetime 'created_at',         null: false
    t.datetime 'updated_at',         null: false
  end

  add_index 'user_submitted_source_records', ['source_fingerprint'], name: 'index_user_submitted_source_records_on_source_fingerprint', unique: true
end
