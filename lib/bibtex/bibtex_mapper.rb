# Note: there is no 'Bibtex' module in sul_pub to avoid any conflicts with other gems
require 'bibtex'

# Convert BibTex content into other formats
class BibtexMapper

  # Convert BibTex authors from pub_hash to CSL authors
  # @param [Hash] pub_hash
  # @return [Array<Hash>] CSL authors
  def self.authors_to_csl(pub_hash)
    authors = pub_hash[:author]
    return [] if authors.blank?
    authors.map do |author|
      author = author.symbolize_keys
      next if author[:name].blank?
      family, given = author[:name].split(',')
      { 'family' => family, 'given' => given }
    end.compact
  end

  # Convert BibTex editors from pub_hash to CSL editors
  # @param [Hash] pub_hash
  # @return [Array<Hash>] CSL editors
  def self.editors_to_csl(pub_hash)
    editors = pub_hash[:editor]
    editors ||= pub_hash[:author].select { |author| author[:role] =~ /editor/i } if pub_hash[:author]
    return [] if editors.blank?
    editors.map do |editor|
      editor = editor.symbolize_keys
      next if editor[:name].blank?
      family, given = editor[:name].split(',')
      { 'family' => family, 'given' => given }
    end.compact
  end

  ARTICLE_TYPE_MAPPING = %w(article misc unpublished).freeze
  BOOK_TYPE_MAPPING = %w(book booklet inbook incollection manual techreport).freeze
  INPROCEEDINGS_TYPE_MAPPING = %w(conference proceedings inproceedings).freeze

  attr_reader :record
  attr_reader :bibtex_type
  attr_reader :identifiers

  # @param [BibTeX::Entry] record
  def initialize(record)
    @record = record
    @bibtex_type = record.type.to_s.strip
    @identifiers = BibtexIdentifiers.new(record)
  end

  # Convert BibTex record to pub_hash
  # @return [Array<Hash>] pub_hash data
  def pub_hash
    @pub_hash ||= begin
      record_as_hash = map_identifiers
      record_as_hash[:provenance] = Settings.batch_source
      record_as_hash[:title] = record.title.to_s.strip if record['title'].present?
      # unless !record["title"].blank && record["title"].blank? then record_as_hash[:title] = record.chapter.to_s.strip end
      record_as_hash[:booktitle] = record.booktitle.to_s.strip if record['booktitle'].present?
      if record['author'].present?
        record_as_hash[:author] = record.author.collect { |a| { name: a.to_s, role: 'author' } }
        record_as_hash[:allAuthors] = record.author.to_a.join(', ')
      end
      if record['editor'].present?
        record_as_hash[:editor] = record.editor.collect { |a| { name: a.to_s, role: 'editor' } }
        record_as_hash[:allEditors] = record.editor.to_a.join(', ')
      end

      record_as_hash[:publisher] = record.publisher.to_s.strip if record['publisher'].present?
      record_as_hash[:year] = record.year.to_s.strip if record['year'].present?
      record_as_hash[:address] = record.address.to_s.strip if record['address'].present?
      record_as_hash[:howpublished] = record.howpublished.to_s.strip if record['howpublished'].present?
      record_as_hash[:edition] = record.edition.to_s.strip if record['edition'].present?
      record_as_hash[:chapter] = record.chapter.to_s.strip if record['chapter'].present?

      record_as_hash[:type] = sul_document_type
      record_as_hash[:bibtex_type] = bibtex_type

      if sul_document_type == Settings.sul_doc_types.inproceedings
        conference_hash = { organization: record['organization'].to_s.strip } if record['organization'].present?
        record_as_hash[:conference] = conference_hash unless conference_hash.nil?
      end

      if sul_document_type == Settings.sul_doc_types.article || record.journal.present?
        journal_hash = {}
        journal_hash[:name] = record.journal.to_s.strip if record['journal'].present?
        journal_hash[:volume] = record.volume.to_s.strip if record['volume'].present?
        journal_hash[:issue] = record.issue.to_s.strip if record['issue'].present?
        journal_hash[:articlenumber] = record.number.to_s.strip if record['number'].present?
        journal_hash[:pages] = record.pages.to_s.strip if record['pages'].present?
        journal_hash[:month] = record.month.to_s.strip if record['month'].present?
        journal_hash[:identifier] = identifiers.pub_hash.select { |id| id[:type] == 'issn' }
        record_as_hash[:journal] = journal_hash unless journal_hash.empty?
      elsif record['pages'].present?
        # if this is an article then the pages go in the article object, but if not put it in the main object.
        record_as_hash[:pages] = record.pages.to_s.strip
      end

      if record['series']
        book_series_hash = {}
        book_series_hash[:identifier] = identifiers.pub_hash.select { |id| id[:type] == 'issn' }
        book_series_hash[:title] = record.series.to_s.strip  if record['series'].present?
        book_series_hash[:volume] = record.volume.to_s.strip if record['volume'].present?
        book_series_hash[:month] = record.month.to_s.strip if record['month'].present?
        record_as_hash[:series] = book_series_hash unless book_series_hash.empty?
      end
      record_as_hash
    end
  end

  def sul_document_type
    @sul_document_type ||= begin
      if ARTICLE_TYPE_MAPPING.include?(bibtex_type)
        Settings.sul_doc_types.article
      elsif BOOK_TYPE_MAPPING.include?(bibtex_type)
        Settings.sul_doc_types.book
      elsif INPROCEEDINGS_TYPE_MAPPING.include?(bibtex_type)
        Settings.sul_doc_types.inproceedings
      end
    end
  end

  private

    # @return [Hash]
    def map_identifiers
      h = {}
      h[:identifier] = identifiers.pub_hash
      h[:doi] = identifiers.doi if identifiers.doi.present?
      h[:isbn] = identifiers.isbn if identifiers.isbn.present?
      h[:issn] = identifiers.issn if identifiers.issn.present?
      h[:pmid] = identifiers.pmid if identifiers.pmid.present?
      h
    end
end

