class RemoveIdentityTypeFromAuthorIdentity < ActiveRecord::Migration[4.2]
  def change
    remove_column :author_identities, :identity_type, :string
  end
end
