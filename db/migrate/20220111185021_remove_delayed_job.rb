class RemoveDelayedJob < ActiveRecord::Migration[6.1]
  def change
    drop_table :delayed_jobs
  end
end
