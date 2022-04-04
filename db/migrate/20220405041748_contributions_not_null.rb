class ContributionsNotNull < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:contributions, :author_id, false)
    change_column_null(:contributions, :publication_id, false)
  end
end
