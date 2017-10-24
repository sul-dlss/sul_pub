require 'identifiers'

# https://github.com/altmetric/identifiers
#
# Identifiers::DOI.extract('example: 10.123/abcd.efghi')
# # => ["10.123/abcd.efghi"]
#
# It can support many identifiers:
# Identifiers::AdsBibcode.extract('')
# Identifiers::ArxivId.extract('')
# Identifiers::DOI.extract('')
# Identifiers::Handle.extract('')
# Identifiers::ISBN.extract('')
# Identifiers::NationalClinicalTrialId.extract('')
# Identifiers::ORCID.extract('')
# Identifiers::PubmedId.extract('')
# Identifiers::RepecId.extract('')
# Identifiers::URN.extract('')

# Parse the identifiers in a PublicationIdentifier
#
# This class should try to work with the input parameter as a read-only object.
# It should only modify it when explicitly asked to `update` it.  If it's
# an active record object, assign new values to it, but don't save it, leave
# that persistence action to the consumer; see the runner script in
# @see script/publication_identifier_normalization.rb
class ParseIdentifier

  URI_PREFIX_DOI = 'http://dx.doi.org/'.freeze
  # URI_PREFIX_ISBN = ''.freeze # maybe there is no such thing?
  URI_PREFIX_PMID = 'https://www.ncbi.nlm.nih.gov/pubmed/'.freeze

  attr_reader :pub_id

  # The pub_id parameter should respond to these fields:
  # pub_id[:identifier_type]
  # pub_id[:identifier_value]
  # pub_id[:identifier_uri]
  # @param pub_id [PublicationIdentifier|Hash]
  def initialize(pub_id)
    @pub_id = pub_id
    raise "#{pub_info} is blank" if value.blank? && uri.blank?
  end

  def type
    pub_id[:identifier_type]
  end

  def value
    pub_id[:identifier_value]
  end

  def uri
    pub_id[:identifier_uri]
  end

  # Update the pub_id with parsed data
  # @return pub_id [PublicationIdentifier|Hash]
  def update
    if type_doi
      pub_id[:identifier_value] = doi
      pub_id[:identifier_uri] = doi_uri
    elsif type_isbn
      pub_id[:identifier_value] = isbn
      pub_id[:identifier_uri] = isbn_uri
    elsif type_pmid
      pub_id[:identifier_value] = pmid
      pub_id[:identifier_uri] = pmid_uri
    end
    pub_id
  end

  # ---
  # DOI

  # Extract a DOI value
  # @return doi [String|nil]
  def doi
    @doi ||= begin
      return nil unless type_doi
      extract_value
    end
  end

  # Extract a DOI URI
  # @return doi_uri [String|nil]
  def doi_uri
    @doi_uri ||= begin
      return nil unless type_doi
      URI_PREFIX_DOI + doi
    end
  end

  # ---
  # ISBN

  # Extract an ISBN value
  # @return isbn [String|nil]
  def isbn
    @isbn ||= begin
      return nil unless type_isbn
      extract_value
    end
  end

  # Extract an ISBN URI
  # @return isbn_uri [String|nil]
  def isbn_uri
    nil # there is no URI
  end

  # ---
  # PMID

  # Extract a PMID value
  # @return pmid [String|nil]
  def pmid
    @pmid ||= begin
      return nil unless type_pmid
      extract_value
    end
  end

  # Extract an PMID URI
  # @return pmid_uri [String|nil]
  def pmid_uri
    @pmid_uri ||= begin
      return nil unless type_pmid
      URI_PREFIX_PMID + pmid
    end
  end

  private

    def extractor
      @extractor ||= if type_doi
                       Identifiers::DOI
                     elsif type_isbn
                       Identifiers::ISBN
                     elsif type_pmid
                       Identifiers::PubmedId
                     end
    end

    def extract_value
      extract = extractor.extract(value).first
      extract = extractor.extract(uri).first if extract.blank?
      msg = "#{type}: #{pub_info} '#{extract}' extracted from '#{value}' or '#{uri}'"
      extract.blank? ? logger.error(msg) : logger.info(msg)
      extract
    end

    def logger
      @logger ||= Logger.new(Rails.root.join('log', 'parse_identifier.log'))
    end

    def pub_info
      @pub_info ||= begin
        id = pub_id[:id] || ''
        pub = pub_id[:publication_id] || 'n/a'
        "#{pub_id.class} #{id}: SulPubID #{pub}:"
      end
    end

    def type_doi
      type =~ /\Adoi\z/i
    end

    def type_isbn
      type =~ /\Aisbn\z/i
    end

    def type_pmid
      type =~ /\Apmid\z/i
    end

end
