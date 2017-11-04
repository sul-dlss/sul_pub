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

# Exception for incorrect instantiation of a parser (not necessarily bad data)
class ParseIdentifierTypeError < StandardError

end

# Exception for blank data
class ParseIdentifierEmptyError < StandardError

end
# Exception for invalid data
class ParseIdentifierInvalidError < StandardError

end

# Parse the identifiers in a PublicationIdentifier
#
# This is a base class for ParseIdentifier* subclasses.
#
# This class should try to work with the input parameter as a read-only object.
# It should only modify it when explicitly asked to `update` it.  If it's
# an active record object, assign new values to it, but don't save it, leave
# that persistence action to the consumer; see the runner script in
# @see script/publication_identifier_normalization.rb
class ParseIdentifier

  attr_reader :pub_id
  attr_reader :type

  # @param pub_id [PublicationIdentifier]
  def initialize(pub_id)
    raise(ArgumentError, 'pub_id must be an PublicationIdentifier') unless pub_id.is_a? PublicationIdentifier
    @pub_id = pub_id
    @type = pub_id[:identifier_type]
    raise(ParseIdentifierTypeError, "INVALID TYPE #{pub_id.inspect}") unless match_type
    raise(ParseIdentifierEmptyError, "EMPTY DATA #{pub_id.inspect}") if empty?
    raise(ParseIdentifierInvalidError, "INVALID DATA #{pub_id.inspect}") unless valid?
  end

  def empty?
    pub_id[:identifier_value].blank? && pub_id[:identifier_uri].blank?
  end

  # Update the pub_id with parsed data
  # @return pub_id [PublicationIdentifier]
  def update
    pub_id[:identifier_value] = value
    pub_id[:identifier_uri] = uri
    pub_id
  end

  # Does the data validate?
  def valid?
    # the base class does no validations
    true
  end

  # Extract a value
  # @return [String|nil]
  def value
    # this base class uses the pub_id value
    @value ||= pub_id[:identifier_value]
  end

  # Extract a URI
  # @return [String|nil]
  def uri
    # this base class uses the pub_id URI
    @uri ||= compose_uri
  end

  private

    # Compose a URI
    # @return [String|nil]
    def compose_uri
      pub_id[:identifier_uri]
    end

    def extractor
      # subclasses can normalize data, otherwise this method should never get called
      raise(NotImplementedError, "There is no ParseIdentifier for a #{type}")
    end

    def extract_value
      # the value should only ever be one identifier, so we can extract the .first
      # and when it fails to extract an identifier, the .first call returns nil
      extract = extractor.extract(pub_id[:identifier_value]).first
      extract = extract_value_from_uri if extract.blank?
      msg = "'#{extract}' extracted from '#{pub_id.inspect}'"
      extract.blank? ? logger.error(msg) : logger.info(msg)
      extract
    end

    def extract_value_from_uri
      extractor.extract(pub_id[:identifier_uri]).first
    end

    def logger
      @logger ||= Logger.new(Rails.root.join('log', 'parse_identifier.log'))
    end

    def match_type
      true # this base class can match anything and does nothing to them
    end
end
