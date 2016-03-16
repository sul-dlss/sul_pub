class SpecifyDatabaseLimits < ActiveRecord::Migration
  ##
  # This migration enforces previously inferred limits automatically selected
  # based on the implemented database. If these limits or indexes are needed,
  # they should be reproducable through the migrations.
  def change
    # changing authors table
    change_column :authors, :cap_profile_id, :integer, limit: 4
    change_column :authors, :sunetid, :string, limit: 255
    change_column :authors, :university_id, :integer, limit: 4
    change_column :authors, :email, :string, limit: 255
    change_column :authors, :cap_first_name, :string, limit: 255
    change_column :authors, :cap_last_name, :string, limit: 255
    change_column :authors, :cap_middle_name, :string, limit: 255
    change_column :authors, :official_first_name, :string, limit: 255
    change_column :authors, :official_last_name, :string, limit: 255
    change_column :authors, :official_middle_name, :string, limit: 255
    change_column :authors, :preferred_first_name, :string, limit: 255
    change_column :authors, :preferred_last_name, :string, limit: 255
    change_column :authors, :preferred_middle_name, :string, limit: 255
    change_column :authors, :california_physician_license, :string, limit: 255
    change_column :authors, :emails_for_harvest, :string, limit: 255

    # changing batch_uploaded_source_records
    change_column :batch_uploaded_source_records, :sunet_id, :string, limit: 255
    change_column :batch_uploaded_source_records, :author_id, :integer, limit: 4
    change_column :batch_uploaded_source_records, :cap_profile_id, :integer, limit: 4
    change_column :batch_uploaded_source_records, :bibtex_source_data, :text, limit: 65535
    change_column :batch_uploaded_source_records, :source_fingerprint, :string, limit: 255
    change_column :batch_uploaded_source_records, :year, :integer, limit: 4
    change_column :batch_uploaded_source_records, :batch_name, :string, limit: 255
    change_column :batch_uploaded_source_records, :error_message, :text, limit: 65535
    change_column :batch_uploaded_source_records, :publication_id, :integer, limit: 4

    # changing contributions
    change_column :contributions, :author_id, :integer, limit: 4
    change_column :contributions, :cap_profile_id, :integer, limit: 4
    change_column :contributions, :publication_id, :integer, limit: 4
    change_column :contributions, :status, :string, limit: 255
    change_column :contributions, :visibility, :string, limit: 255

    # changing publication_indentifiers
    change_column :publication_identifiers, :publication_id, :integer, limit: 4
    change_column :publication_identifiers, :identifier_type, :string, limit: 255
    change_column :publication_identifiers, :identifier_value, :string, limit: 255
    change_column :publication_identifiers, :identifier_uri, :string, limit: 255
    change_column :publication_identifiers, :certainty, :string, limit: 255
    
    # changing publications
    change_column :publications, :same_as_publications_id, :integer, limit: 4
    change_column :publications, :year, :integer, limit: 4
    change_column :publications, :lock_version, :integer, limit: 4
    change_column :publications, :xml, :text, limit: 65535
    change_column :publications, :pmid, :integer, limit: 4
    change_column :publications, :sciencewire_id, :integer, limit: 4
    change_column :publications, :pages, :string, limit: 255
    change_column :publications, :issn, :string, limit: 255
    change_column :publications, :publication_type, :string, limit: 255

    # changing pubmed_source_records
    change_column :pubmed_source_records, :source_data, :text, limit: 65535
    change_column :pubmed_source_records, :pmid, :integer, limit: 4
    change_column :pubmed_source_records, :lock_version, :integer, limit: 4
    change_column :pubmed_source_records, :source_fingerprint, :string, limit: 255

    # changing sciencewire_source_records
    change_column :sciencewire_source_records, :source_data, :text, limit: 65535
    change_column :sciencewire_source_records, :pmid, :integer, limit: 4
    change_column :sciencewire_source_records, :sciencewire_id, :integer, limit: 4
    change_column :sciencewire_source_records, :lock_version, :integer, limit: 4
    change_column :sciencewire_source_records, :source_fingerprint, :string, limit: 255

    # changing user_submitted_source_records
    change_column :user_submitted_source_records, :source_data, :text, limit: 65535
    change_column :user_submitted_source_records, :pmid, :integer, limit: 4
    change_column :user_submitted_source_records, :lock_version, :integer, limit: 4
    change_column :user_submitted_source_records, :source_fingerprint, :string, limit: 255
    change_column :user_submitted_source_records, :year, :integer, limit: 4
    change_column :user_submitted_source_records, :publication_id, :integer, limit: 4
    change_column :user_submitted_source_records, :author_id, :integer, limit: 4

    # changing user_submitted_source_records
    change_column :versions, :item_type, :string, limit: 255, null: false
    change_column :versions, :item_id, :integer, limit: 4, null: false
    change_column :versions, :event, :string, limit: 255, null: false
    change_column :versions, :whodunnit, :string, limit: 255
    change_column :versions, :object, :text, limit: 65535
  end
end
