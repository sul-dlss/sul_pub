module ScienceWire
  module Query
    ##
    # Creates a ConferenceProceedingDocumentSuggestion query XML document string
    class ConferenceProceedingDocumentSuggestion < ScienceWire::Query::Suggestion
      ##
      # @param [ScienceWire::AuthorAttributes] author_attributes
      def initialize(author_attributes)
        super(author_attributes, 'Conference Proceeding Document')
      end
    end
  end
end
