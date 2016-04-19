module ScienceWire
  module Query
    class Suggestion
      attr_reader :last_name, :first_name, :middle_name, :email, :seed_list, :category
      def initialize(last_name, first_name, middle_name, email, seed_list, category)
        @last_name = last_name
        @first_name = first_name
        @middle_name = middle_name
        @email = email
        @seed_list = seed_list
        @category = category
      end

      def generate
        opening_block << authors_block << email_block << seed_list_block << closing_block
      end

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
              <LastName>#{last_name}</LastName>
              <FirstName>#{first_name}</FirstName>
              <MiddleName>#{middle_name}</MiddleName>
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
        if email.present?
          <<-XML.strip_heredoc
            <Emails>
              <string>#{email}</string>
            </Emails>
          XML
        else
          ''
        end
      end

      def seed_list_block
        if seed_list.present?
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
        seed_list.collect { |pubId| "<int>#{pubId}</int>" }.join
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
