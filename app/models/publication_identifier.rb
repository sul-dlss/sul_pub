class PublicationIdentifier < ActiveRecord::Base
  belongs_to :publication, required: true, inverse_of: :publication_identifiers

  # A PubHash[:identifier] entry
  # @return identifier [Hash]
  def identifier
    ident_hash = {}
    ident_hash[:type] = identifier_type if identifier_type.present?
    ident_hash[:id] = identifier_value if identifier_value.present?
    ident_hash[:url] = identifier_uri if identifier_uri.present?
    ident_hash
  end
end
