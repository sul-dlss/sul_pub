class PublicationIdentifier < ActiveRecord::Base
  attr_accessible :certainty, :identifier_type, :identifier_value, :identifier_uri, :publication_id
  belongs_to :publication

end






