module ScienceWire
  module Query
    ##
    # Creates a Suggestion query XML document string
    class Suggestion
      attr_reader :author_attributes, :category
      ##
      # @param [ScienceWire::AuthorAttributes] author_attributes
      # @param [String] category
      def initialize(author_attributes, category)
        @author_attributes = author_attributes
        @category = category
      end

      def generate
        opening_block << authors_block << email_block << seed_list_block << closing_block
      end

      private

        def opening_block
          <<-XML.strip_heredoc
            <?xml version='1.0'?>
            <PublicationAuthorMatchParameters xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
              xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
          XML
        end

        # The ScienceWire API documentation does not include a <Version> element
        # within the <Author>.  When asked about this element, they say "... we
        # essentially implemented a custom recommendation algorithm for Stanford
        # to use, behind the MatchedPublicationItemIdsForAuthor API. Because
        # that API is called elsewhere in TR, we did not simply want to
        # overwrite the old algorithm with the new and thus this <Version> flag
        # essentially says 'use the new algorithm.' I believe if you make the
        # call without the <Version> value present, you will get recommendations
        # via the old algorithm."

        def authors_block
          <<-XML.strip_heredoc
            <Authors>
              <Author>
                <LastName>#{author_attributes.name.last}</LastName>
                <FirstName>#{author_attributes.name.first}</FirstName>
                <MiddleName>#{author_attributes.name.middle}</MiddleName>
                #{author_attributes.institution.address.to_xml}
                <Version>1</Version>
              </Author>
            </Authors>
            <DocumentCategory>#{category}</DocumentCategory>
          XML
        end

        def email_block
          return '' unless author_attributes.email.present?
          <<-XML.strip_heredoc
            <Emails>
              <string>#{author_attributes.email}</string>
            </Emails>
          XML
        end

        def seed_list_block
          return '' unless author_attributes.seed_list.present?
          <<-XML.strip_heredoc
            <PublicationItemIds>
              #{seed_ints}
            </PublicationItemIds>
          XML
        end

        def seed_ints
          author_attributes.seed_list.collect { |pubId| "<int>#{pubId}</int>" }.join
        end

        def closing_block
          <<-XML.strip_heredoc
            <LimitToHighQualityMatchesOnly>true</LimitToHighQualityMatchesOnly>
          </PublicationAuthorMatchParameters>
          XML
        end
    end
  end
end
