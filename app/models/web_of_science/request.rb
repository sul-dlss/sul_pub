module WebOfScience
  # A base class for request functionality
  # Needs to retain the HTTP response and response document for debugging
  # and establish a pattern for an individual request class to provide a more semantic interface.
  # For example, a consumer of a request class really wants IDs or Records, not XML.
  class Request
    attr_reader :client, :template
    attr_accessor :request_body, :response

    # @param [WebOfScience::Client] client
    # @param [String] template
    def initialize(client, template)
      @client = client
      @template = template
    end

    # @param [String] body request body XML
    # @return [Array<Integer>] identifiers
    def pub_ids_for_author(body)
      response = request(
        body: body # path: '/PublicationCatalog/MatchedPublicationItemIdsForAuthor'
      )
      response
        .xpath('/ArrayOfItemMatchResult/ItemMatchResult/PublicationItemID') # parse differently
        .map { |item| item.text.to_i }
    end

    alias matched_publication_item_ids_for_author_and_parse pub_ids_for_author

    # @param [Array<String>] ids PublicationItemId values (no whitespace)
    # @return [Nokogiri::XML::Document] response body
    # @note previously had timeout_period: 500, but probably unneccessary w/ new API limits
    def publication_items(ids)
      request(body: render('web_of_science/retrieve_by_id', :@uids => ids))
    end
  end
end
