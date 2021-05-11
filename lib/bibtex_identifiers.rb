# NOTE: there is no 'Bibtex' module in sul_pub to avoid any conflicts with other gems
require 'bibtex'
require 'forwardable'

# An immutable Hash of BibTeX identifiers
class BibtexIdentifiers
  extend Forwardable
  include Enumerable

  # Delegate enumerable methods to the Hash.
  # This is just a convenience.
  delegate %i(each keys values has_key? has_value? include? reject select to_json) => :to_h

  # @param [BibTeX::Entry] record
  def initialize(record)
    raise(ArgumentError, 'ids must be a BibTex::Entry') unless record.is_a? BibTeX::Entry
    extract_ids(record)
  end

  # @return [String, nil]
  def doi
    ids['doi']
  end

  # @return [String, nil]
  def doi_uri
    "#{Settings.DOI.BASE_URI}#{doi}" if doi.present?
  end

  # @return [String, nil]
  def isbn
    ids['isbn']
  end

  # @return [String, nil]
  def isbn_uri
    "#{Settings.SULPUB_ID.SEARCHWORKS_URI}#{isbn}" if isbn.present?
  end

  # @return [String, nil]
  def issn
    ids['issn']
  end

  # @return [String, nil]
  def issn_uri
    "#{Settings.SULPUB_ID.SEARCHWORKS_URI}#{issn}" if issn.present?
  end

  # @return [String, nil]
  def pmid
    ids['pmid']
  end

  # @return [String, nil]
  def pmid_uri
    "#{Settings.PUBMED.ARTICLE_BASE_URI}#{pmid}" if pmid.present?
  end

  # A mutable Hash of the identifiers
  # @return [Hash<String => String>]
  def to_h
    hash = {}
    if doi.present?
      hash['doi']     = doi
      hash['doi_uri'] = doi_uri
    end
    if isbn.present?
      hash['isbn']     = isbn
      hash['isbn_uri'] = isbn_uri
    end
    if issn.present?
      hash['issn']     = issn
      hash['issn_uri'] = issn_uri
    end
    if pmid.present?
      hash['pmid']     = pmid
      hash['pmid_uri'] = pmid_uri
    end
    hash
  end

  # @return [Array<Hash>]
  def pub_hash
    ids = []
    ids << { type: 'doi',  id: doi,  url: doi_uri  } if doi.present?
    ids << { type: 'isbn', id: isbn, url: isbn_uri } if isbn.present?
    ids << { type: 'issn', id: issn, url: issn_uri } if issn.present?
    ids << { type: 'pmid', id: pmid, url: pmid_uri } if pmid.present?
    ids
  end

  private

    attr_reader :ids

    # @param [BibTeX::Entry] record
    # @return [void]
    def extract_ids(record)
      @ids = {}
      doi = extract_id(record, 'doi')
      isbn = extract_id(record, 'isbn')
      issn = extract_id(record, 'issn')
      pmid = extract_id(record, 'pmid')
      ids['doi'] = doi if doi.present?
      ids['isbn'] = isbn if isbn.present?
      ids['issn'] = issn if issn.present?
      ids['pmid'] = pmid if pmid.present?
      ids.freeze
    end

    # @param [BibTeX::Entry] record
    # @param [String] type
    # @return [String]
    def extract_id(record, type)
      record[type.downcase].to_s || record[type.upcase].to_s
    end
end
