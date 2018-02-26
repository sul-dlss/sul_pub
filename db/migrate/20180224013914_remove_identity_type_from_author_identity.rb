class RemoveIdentityTypeFromAuthorIdentity < ActiveRecord::Migration
  def change
    remove_column :author_identities, :identity_type, :string
  end
end
