#
# Switch our data-oriented `:text` columns to 16MBs (MySQL's MEDIUMTEXT)
#
class SwitchToMediumText < ActiveRecord::Migration[4.2]
  def change
    # changing batch_uploaded_source_records
    change_column :batch_uploaded_source_records, :bibtex_source_data, :text, limit: 16_777_215
    change_column :batch_uploaded_source_records, :error_message, :text, limit: 16_777_215

    # changing publications
    change_column :publications, :xml, :text, limit: 16_777_215

    # changing pubmed_source_records
    change_column :pubmed_source_records, :source_data, :text, limit: 16_777_215

    # changing sciencewire_source_records
    change_column :sciencewire_source_records, :source_data, :text, limit: 16_777_215

    # changing user_submitted_source_records
    change_column :user_submitted_source_records, :source_data, :text, limit: 16_777_215

    # changing versions
    change_column :versions, :object, :text, limit: 16_777_215
  end
end
