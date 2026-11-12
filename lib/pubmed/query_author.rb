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

    # Each name is searched as quoted phrases so PubMed can't rewrite it.  Unquoted, a name PubMed doesn't
    # know (e.g. "Lastname, David[Author]") is split up or has the last name dropped, leaving "david[Author]".
    # A quoted phrase PubMed doesn't know returns nothing instead.  The quoted name alone only matches that
    # exact name, so we also search "Lastname, First *" to keep middle names and initials ("Lastname, First B").
    def name_term
      author_identities.collect do |identity|
        next unless valid_name?(identity)

        name = "#{identity.last_name}, #{identity.first_name}".delete('"')
        "(\"#{name}\"[Author] OR \"#{name} *\"[Author])"
      end.compact.uniq.join(' OR ')
    end

    def valid_name?(identity)
      identity.first_name =~ /[a-zA-Z]+/ && identity.last_name =~ /[a-zA-Z]+/ &&
        INVALID_NAME_TERMS.exclude?(identity.first_name.downcase) &&
        INVALID_NAME_TERMS.exclude?(identity.last_name.downcase)
    end

    def affiliation_term
      author_identities.collect { |identity| affiliation_terms(identity.institution) if identity.institution }
                       .flatten.compact.uniq.join(' OR ')
    end

    # Quoted for the same reason as names: unquoted, PubMed drops any word of an institution it doesn't know
    # (e.g. "Unknownword College[Affiliation]" runs as "College"[Affiliation]) and reports PhraseNotFound,
    # which would make parse_response discard all of the author's results, including the good Stanford ones.
    # A quoted institution PubMed doesn't know just matches nothing (reported only as a warning).
    #
    # Publications can produce an institution with '&' or with 'and' (e.g. "Oregon Health & Science University" vs
    # "Oregon Health and Science University"), and the two forms match different records, so search both.
    # Whitespace is squished so identities that differ only in spacing (e.g. a trailing space) don't add
    # duplicate terms.
    # @return [Array<String>]
    def affiliation_terms(institution)
      institution = institution.delete('"').squish
      return [] if institution.blank?

      variants = [institution]
      variants << institution.gsub(/\s*&\s*/, ' and ') if institution.include?('&')
      variants.map { |variant| "\"#{variant}\"[Affiliation]" }
    end

    def term
      "(#{name_term}) AND (#{affiliation_term})"
    end

    # When PubMed cannot find part of the query (e.g. an author's last name), it silently drops that part
    # and runs the rest, reporting the dropped phrases in ErrorList/PhraseNotFound.  For a name query that
    # means "(Lastname, David[Author])" becomes "david[Author]", which matches everyone with the last name David.
    # Those results are for a different query than the one we sent, so we discard them.
    def parse_response(response)
      xml = Nokogiri::XML(response)
      phrases_not_found = xml.xpath('//ErrorList/PhraseNotFound').map(&:text)
      if phrases_not_found.any?
        Pubmed.logger.warn("Pubmed::QueryAuthor - author #{author.id} - discarding results: PubMed did not find " \
                           "#{phrases_not_found.inspect} and ran #{xml.at('QueryTranslation')&.text.inspect} instead of #{term.inspect}")
        return []
      end

      xml.xpath('//IdList/Id/text()').map(&:text)
    end
  end
end
