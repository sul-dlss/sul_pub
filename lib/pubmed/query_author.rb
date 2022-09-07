# frozen_string_literal: true

module Pubmed
  # Use author name-institution logic to find Pubmed publications for an Author
  class QueryAuthor
    # NOTE: If you send a name query with of these terms as a first or last name, Pubmed will not produce
    #  a correct query and return too many results. Any of these names will make the query invalid.
    #  see https://github.com/sul-dlss/sul_pub/issues/1546
    INVALID_NAME_TERMS = %w[or and not].freeze

    def initialize(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author

      @options = options
      @author = author
    end

    # Find all pmids for an author
    # @return [Array<String>] pmids
    def pmids
      return [] unless valid?

      resp = client.search(term, addl_args)
      parse_response(resp)
    end

    def valid?
      name_term.present?
    end

    private

    delegate :client, to: :Pubmed

    attr_reader :author, :options

    def addl_args
      return unless options[:reldate]

      "reldate=#{options[:reldate]}&datetype=edat"
    end

    def author_identities
      @author_identities ||= [author].concat(author.author_identities.to_a)
    end

    def name_term
      author_identities.collect do |identity|
        "(#{identity.last_name}, #{identity.first_name}[Author])" if valid_name?(identity)
      end.compact.uniq.join(' OR ')
    end

    def valid_name?(identity)
      identity.first_name =~ /[a-zA-Z]+/ && identity.last_name =~ /[a-zA-Z]+/ &&
        INVALID_NAME_TERMS.exclude?(identity.first_name.downcase) &&
        INVALID_NAME_TERMS.exclude?(identity.last_name.downcase)
    end

    def affiliation_term
      author_identities.collect { |identity| affiliation_terms(identity.institution) if identity.institution }
                       .compact.uniq.join(' OR ')
    end

    def affiliation_terms(institution)
      if institution.include?('&')
        "#{institution.gsub('&', 'and')}[Affiliation]"
      else
        "#{institution}[Affiliation]"
      end
    end

    def term
      "(#{name_term}) AND (#{affiliation_term})"
    end

    def parse_response(response)
      Nokogiri::XML(response).xpath('//IdList/Id/text()').map(&:text)
    end
  end
end
