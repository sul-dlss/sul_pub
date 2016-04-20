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

        def authors_block
          <<-XML.strip_heredoc
            <Authors>
              <Author>
                <LastName>#{author_attributes.last_name}</LastName>
                <FirstName>#{author_attributes.first_name}</FirstName>
                <MiddleName>#{author_attributes.middle_name}</MiddleName>
                <City>Stanford</City>
                <State>CA</State>
                <Country>USA</Country>
                <Version>1</Version>
              </Author>
            </Authors>
            <DocumentCategory>#{category}</DocumentCategory>
          XML
        end

        def email_block
          if author_attributes.email.present?
            <<-XML.strip_heredoc
              <Emails>
                <string>#{author_attributes.email}</string>
              </Emails>
            XML
          else
            ''
          end
        end

        def seed_list_block
          if author_attributes.seed_list.present?
            <<-XML.strip_heredoc
              <PublicationItemIds>
                #{seed_ints}
              </PublicationItemIds>
            XML
          else
            ''
          end
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
