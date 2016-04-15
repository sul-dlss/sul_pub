require 'science_wire/api/matched_publication_item_ids_for_author'
require 'science_wire/api/publication_items'
require 'science_wire/api/publication_query'

module ScienceWire
  ##
  # Top level module for ScienceWire API endpoints
  module API
    include ScienceWire::API::MatchedPublicationItemIdsForAuthor
    include ScienceWire::API::PublicationItems
    include ScienceWire::API::PublicationQuery
  end
end
