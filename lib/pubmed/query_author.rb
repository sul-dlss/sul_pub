module Pubmed

  # Use author name-institution logic to find Pubmed publications for an Author
  class QueryAuthor
    def initialize(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author
      @options = options
      @author = author
    end

    # Find all pmids for an author
    # @return [Array<String>] pmids
    def pmids
      resp = client.search(term, addl_args)
      parse_response(resp)
    end

    private

    delegate :client, to: :Pubmed

    attr_reader :author, :options
      def addl_args
        return unless options[:reldate]

        "reldate=#{options[:reldate]}&datetype=edat"
      end

      def term
        author_identities = [author].concat(author.author_identities.to_a)
        name_term = author_identities.collect { |identity| "(#{identity.last_name} #{identity.first_name}[Author])" }
                                     .uniq.join(' OR ')
        affiliation_term = author_identities.collect { |identity| "#{identity.institution}[Affiliation]" if identity.institution }
                                            .compact.uniq.join(' OR ')
        "(#{name_term}) AND (#{affiliation_term})"
      end

      def parse_response(response)
        Nokogiri::XML(response).xpath('//IdList/Id/text()').map(&:text)
      end

  end
end