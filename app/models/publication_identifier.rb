class PublicationIdentifier < ActiveRecord::Base
  belongs_to :publication, required: true, inverse_of: :publication_identifiers
end
