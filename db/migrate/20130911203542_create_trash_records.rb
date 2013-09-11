class CreateTrashRecords < ActiveRecord::Migration
  def change
    ActsAsTrashable::TrashRecord.create_table
  end
end
