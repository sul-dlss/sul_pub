# frozen_string_literal: true

class PublicationIdentifier < ActiveRecord::Base
  belongs_to :publication, required: true, inverse_of: :publication_identifiers
  validates :identifier_type, presence: true

  # @return [Hash<Symbol => String>] an entry for pub_hash[:identifier]
  def identifier
    ident_hash = {}
    ident_hash[:type] = identifier_type if identifier_type.present?
    ident_hash[:id] = identifier_value if identifier_value.present?
    ident_hash[:url] = identifier_uri if identifier_uri.present?
    ident_hash
  end

  # Update the identifier_type entries in publication.pub_hash[:identifier];
  # the publication is not persisted by this method, to
  # avoid complex recurrent call stacks in the rails callback stack.
  # @param delete [Boolean] delete this identifier from pub_hash[:identifier]
  def pub_hash_update(delete: false)
    publication.pub_hash[:identifier] = pub_hash_reject
    publication.pub_hash[:identifier] << identifier unless delete
  end

  private

  # Reject all pub_id.identifier_type entries from pub_id.publication.pub_hash[:identifier]
  # - the pub_hash[:identifier] is not modified by this method
  # @return [Hash]
  def pub_hash_reject
    pub_ids = publication.pub_hash[:identifier] || []
    pub_ids.reject { |id| id[:type] == identifier_type }
  end
end
