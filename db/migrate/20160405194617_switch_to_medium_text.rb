class SwitchToMediumText < ActiveRecord::Migration[4.2]
  def change
    # changing batch_uploaded_source_records
    change_column :batch_uploaded_source_records, :bibtex_source_data, :text
    change_column :batch_uploaded_source_records, :error_message, :text

    # changing publications
    change_column :publications, :xml, :text

    # changing pubmed_source_records
    change_column :pubmed_source_records, :source_data, :text

    # changing sciencewire_source_records
    change_column :sciencewire_source_records, :source_data, :text

    # changing user_submitted_source_records
    change_column :user_submitted_source_records, :source_data, :text

    # changing versions
    change_column :versions, :object, :text
  end
end
