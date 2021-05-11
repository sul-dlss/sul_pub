# frozen_string_literal: true

require 'nokogiri'

class PubmedSourceRecord < ApplicationRecord
  # validates_uniqueness_of :pmid
  # validates_presence_of :source_data

  def self.get_pub_by_pmid(pmid)
    pubmed_record = PubmedSourceRecord.for_pmid(pmid)
    return if pubmed_record.nil?

    pub = Publication.new(
      active: true,
      pmid: pmid,
      pub_hash: pubmed_record.source_as_hash
    )
    pub.sync_publication_hash_and_db
    pub.save
    pub
  end

  def self.for_pmid(pmid)
    find_by(pmid: pmid) || get_pubmed_record_from_pubmed(pmid)
  end

  # @return [PubmedSourceRecord] the recently downloaded pubmed_source_records data
  def self.get_pubmed_record_from_pubmed(pmid)
    return unless Settings.PUBMED.lookup_enabled

    get_and_store_records_from_pubmed([pmid])
    find_by(pmid: pmid)
  end
  private_class_method :get_pubmed_record_from_pubmed

  def self.create_pubmed_source_record(pmid, pub_doc)
    where(pmid: pmid).first_or_create(
      pmid: pmid,
      source_data: pub_doc.to_xml,
      is_active: true,
      source_fingerprint: Digest::SHA2.hexdigest(pub_doc)
    )
  end

  # rubocop:disable Metrics/AbcSize
  def self.get_and_store_records_from_pubmed(pmids)
    pmidValuesForPost = pmids.uniq.collect { |pmid| "&id=#{pmid}" }.join
    the_incoming_xml = Pubmed.client.fetch_records_for_pmid_list pmidValuesForPost
    source_records = Nokogiri::XML(the_incoming_xml).xpath('//PubmedArticle').map do |pub_doc|
      pmid = pub_doc.xpath('MedlineCitation/PMID').text
      begin
        PubmedSourceRecord.new(
          pmid: pmid,
          source_data: pub_doc.to_xml,
          is_active: true,
          source_fingerprint: Digest::SHA2.hexdigest(pub_doc)
        )
      rescue StandardError => e
        NotificationManager.error(e, "Cannot create PubmedSourceRecord with pmid: #{pmid}", self)
      end
    end
    import source_records.compact
  end
  # rubocop:enable Metrics/AbcSize
  private_class_method :get_and_store_records_from_pubmed

  # Retrieve this pubmed record from PubMed and update
  # is_active, source_data and the source_fingerprint fields.
  # Used to update the pubmed source record on our end
  # @return [Boolean] the return value from update!
  def pubmed_update
    return false unless Settings.PUBMED.lookup_enabled

    pubmed_source_xml = Pubmed.client.fetch_records_for_pmid_list pmid
    pub_doc = Nokogiri::XML(pubmed_source_xml).xpath('//PubmedArticle')[0]
    return false unless pub_doc

    attrs = {}
    attrs[:source_data] = pub_doc.to_xml
    attrs[:source_fingerprint] = Digest::SHA2.hexdigest(pub_doc)
    update! attrs
  end

  def extract_abstract_from_pubmed_record(pubmed_record)
    pubmed_record.xpath('MedlineCitation/Article/Abstract/AbstractText').text
  end

  def extract_mesh_headings_from_pubmed_record(pubmed_record)
    mesh_headings_for_record = []
    pubmed_record.xpath('MedlineCitation/MeshHeadingList/MeshHeading').each do |mesh_heading|
      descriptors = []
      qualifiers = []
      mesh_heading.xpath('DescriptorName').each do |descriptor_name|
        descriptors << { major: descriptor_name.attr('MajorTopicYN'), name: descriptor_name.text }
      end
      mesh_heading.xpath('QualifierName').each do |qualifier_name|
        qualifiers << { major: qualifier_name.attr('MajorTopicYN'), name: qualifier_name.text }
      end
      mesh_headings_for_record << { descriptor: descriptors, qualifier: qualifiers }
    end
    mesh_headings_for_record
  end

  # Convert MEDLINE®PubMed® XML to pub_hash
  # @param [Nokogiri::XML::Node] publication
  # @return [Hash<Symbol => Object>] pub_hash
  # @see https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html XML Element Descriptions and their Attributes
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def source_as_hash(publication = Nokogiri::XML(source_data).xpath('//PubmedArticle'))
    record_as_hash = {}
    pmid = publication.xpath('MedlineCitation/PMID').text

    abstract = extract_abstract_from_pubmed_record(publication)
    mesh_headings = extract_mesh_headings_from_pubmed_record(publication)

    record_as_hash[:provenance] = Settings.pubmed_source
    record_as_hash[:pmid] = pmid

    if publication.xpath('MedlineCitation/Article/ArticleTitle').present?
      record_as_hash[:title] =
        publication.xpath('MedlineCitation/Article/ArticleTitle').text
    end
    record_as_hash[:abstract] = abstract if abstract.present?

    # See No. 20 at https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
    #
    # USE OF LISTS AND ATTRIBUTE "CompleteYN" Three of the elements
    # (<AuthorList>, <GrantList>, and <DataBankList>) use "lists" with the
    # corresponding attribute of 'CompleteYN". 'Y', meaning Yes, represents that
    # NLM has entered all list items that appear in the published journal
    # article. 'N', meaning No, represents that NLM has not entered all list
    # items that appear in the published journal article. The latter case
    # (incomplete list) occurs on records created during periods of time when
    # NLM policy was to enter fewer than all items that qualified. NLM
    # recommends the following when encountering 'N' for the element lists:
    #
    # <AuthorList> when attribute = N, then supply the literal "et al." after last author name
    author_list = publication.xpath('MedlineCitation/Article/AuthorList/Author')
    record_as_hash[:author] = author_list.map { |a| author_to_hash(a) }.compact

    record_as_hash[:mesh_headings] = mesh_headings if mesh_headings.present?
    year_xpaths = [
      'MedlineCitation/Article/Journal/JournalIssue/PubDate/Year',
      'MedlineCitation/Article/ArticleDate/Year',
      'PubmedData/History/PubMedPubDate[@PubStatus="accepted"]/Year'
    ]
    # look for a year in all of the xpath locations above in order
    #  stop after the first produces something that looks like a year
    year_xpaths.each do |path|
      match = publication.xpath(path).text.match(/[12][0-9]{3}/)
      next unless match

      record_as_hash[:year] = match.to_s
      break
    end

    record_as_hash[:type] = Settings.sul_doc_types.article

    # record_as_hash[:publisher] =  publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
    # record_as_hash[:city] = publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
    # record_as_hash[:stateprovince] = publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
    if publication.xpath('MedlineCitation/MedlineJournalInfo/Country').present?
      record_as_hash[:country] =
        publication.xpath('MedlineCitation/MedlineJournalInfo/Country').text
    end

    if publication.xpath('MedlineCitation/Article/Pagination/MedlinePgn').present?
      record_as_hash[:pages] =
        publication.xpath('MedlineCitation/Article/Pagination/MedlinePgn').text
    end

    journal_hash = {}
    if publication.xpath('MedlineCitation/Article/Journal/Title').present?
      journal_hash[:name] =
        publication.xpath('MedlineCitation/Article/Journal/Title').text
    end
    if publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').present?
      journal_hash[:volume] =
        publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').text
    end
    if publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').present?
      journal_hash[:issue] =
        publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').text
    end
    # journal_hash[:articlenumber] = publication.xpath('ArticleNumber') unless publication.xpath('ArticleNumber').blank?
    # journal_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?
    journal_identifiers = []
    issn = publication.xpath('MedlineCitation/Article/Journal/ISSN').text
    record_as_hash[:issn] = issn if issn.present?
    journal_identifiers << { type: 'issn', id: issn, url: Settings.SULPUB_ID.SEARCHWORKS_URI + issn } if issn.present?
    journal_hash[:identifier] = journal_identifiers
    record_as_hash[:journal] = journal_hash

    record_as_hash[:identifier] = [{ type: 'PMID', id: pmid, url: "#{Settings.PUBMED.ARTICLE_BASE_URI}#{pmid}" }]
    # the DOI can be in one of two places: ArticleId or ELocationID
    doi = publication.at_xpath('//ArticleId[@IdType="doi"]')
    doi = publication.at_xpath('//ELocationID[@EIdType="doi"]') unless doi.present? && doi.text.present?
    if doi.present? && doi.text.present?
      record_as_hash[:identifier] << { type: 'doi', id: doi.text,
                                       url: "#{Settings.DOI.BASE_URI}#{doi.text}" }
    end
    pmc = publication.at_xpath('//ArticleId[@IdType="pmc"]')
    record_as_hash[:identifier] << { type: 'pmc', id: pmc.text } if pmc.present? && pmc.text.present?
    record_as_hash
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  protected

  # Parse <Author>
  # See No. 20 at https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
  #
  # Personal name <Author> data resides in the following elements:
  # <LastName> contains the surname
  # <ForeName> contains the remainder of name except for suffix
  # <Suffix> contains a valid MEDLINE suffix (e.g., 2nd, or 3rd, etc., Jr or Sr).
  #          Honorifics (e.g., PhD, MD, etc.) are not carried in the data.
  # <Initials> contains up to two initials
  # <Identifier> was added to <AuthorList> with the 2010 DTD, but was not used
  #              until 2013. It is defined to contain a unique identifier associated
  #              with the name. The value in the Identifier attribute Source designates
  #              the organizational authority that established the unique identifier.
  #              Identifier was renamed from NameID with the 2013 DTD. For example,
  #              <Identifier Source="ORCID">0000000179841889</Identifier>.
  # <AffiliationInfo> was added to <AuthorList> with the 2015 DTD. The <AffiliationInfo>
  #                   envelope element includes <Affliliation> and <Identifier>.
  #
  # @param author [Nokogiri::XML::Element] an <Author> element
  # @return [Hash<Symbol => String>] with keys :firstname, :middlename and :lastname
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def author_to_hash(author)
    # <Author> examples provide many variations at No. 20 from
    # https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
    ##
    # Ignore an empty <Author/> element
    return if author.children.empty?
    # Ignore an <Author> that contains <CollectiveName>
    return if author.xpath('CollectiveName').present?
    # Ignore an <Author ValidYN="N"> or missing ValidYN attribute
    return if author.attributes['ValidYN'].present? && author.attributes['ValidYN'].value == 'N'

    # Extract name elements
    lastname = author.xpath('LastName').text
    forename = author.xpath('ForeName').text
    initials = author.xpath('Initials').text
    # Parse <Forename>
    # Forename is everything after the last name and it can be mostly parsed
    # by splitting it on whitespace.  Even when ForeName is only initials,
    # there will be spaces between initials.
    fn, mn = forename.split
    # If ForeName includes particles, the first name is
    # likely to be OK, but the middle name needs to be fixed.
    if forename =~ / el-| el | da | de | del | do | dos | du | le /
      # Try to scan this to keep the particles with the following name.
      # Assume the first name begins with an upper case letter, so this
      # scan pattern will skip over it.
      mn = forename.scan(/[[:lower:]]+[ -][[:upper:]][[:lower:]]*/).first
    end
    ##
    # Parse <Initials>
    # Scan the initials to split it, allowing lower-case particles, dashes and
    # spaces prior to a single upper case initial, e.g
    # 'AB'.scan(/[[:lower:] -]*[[:upper:]]/) => ["A", "B"]
    # 'Mdel R'.scan(/[[:lower:] -]*[[:upper:]]/) => ["M", "del R"]
    # <ForeName>Mohamed el-Walid</ForeName>
    # <Initials>Mel- W</Initials>
    # 'Mel- W'.scan(/[[:lower:] -]*[[:upper:]]/) => ["M", "el- W"]
    initials = initials.scan(/[[:lower:] -]*[[:upper:]]/)
    # Remove an additional space added for hyphenated particles.
    initials = initials.map { |initial| initial.sub('- ', '-') }
    if initials.length >= 1
      # If there is no data from <Forename>, use this first initial
      fn = initials[0] if fn.blank?
      # If there is no data from <Forename>, use this middle initial
      mn = initials[1] if mn.blank? && initials.length > 1
    end
    # Currently ignoring <Suffix> data
    {
      firstname: fn,
      middlename: mn,
      lastname: lastname
    }
    # TODO: extract Identifier
    # <Identifier> was added to <AuthorList> with the 2010 DTD, but was not used until 2013.
    # <Identifier Source="ORCID">0000000179841889</Identifier>
    ##
    # TODO: extract Affiliation
    # <AffiliationInfo> was added to <AuthorList> with the 2015 DTD.
    # The <AffiliationInfo> envelope element includes <Affliliation> and <Identifier>.
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
