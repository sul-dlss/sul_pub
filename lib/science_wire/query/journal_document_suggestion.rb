module ScienceWire
  module Query
    ##
    # Creates a JournalDocumentSuggestion query XML document string
    class JournalDocumentSuggestion < ScienceWire::Query::Suggestion
      ##
      # @param [ScienceWire::AuthorAttributes] author_attributes
      def initialize(author_attributes)
        super(author_attributes, 'Journal Document')
      end
    end
  end
end
