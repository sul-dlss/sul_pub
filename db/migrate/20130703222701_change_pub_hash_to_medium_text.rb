class ChangePubHashToMediumText < ActiveRecord::Migration[4.2]
  def change
    # This migration was created when Argo ran on MySQL. The :text datatype is
    # unlimited in Postgres so it does not need its limit bumped up. This
    # migration is a no-op. Left the former migration commented out for
    # posterity.
    #
    # change_column :publications, :pub_hash, :text, limit: 16_777_215
  end
end
