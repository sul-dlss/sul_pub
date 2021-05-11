# frozen_string_literal: true

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
        "(#{identity.last_name}, #{identity.first_name}[Author])" if identity.first_name =~ /[a-zA-Z]+/
      end
                       .compact.uniq.join(' OR ')
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
