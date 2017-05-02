require 'nokogiri'
require 'nokogiri'

class PubmedSourceRecord < ActiveRecord::Base
  # validates_uniqueness_of :pmid
  # validates_presence_of :source_data

  def source_as_hash
    convert_pubmed_publication_doc_to_hash(Nokogiri::XML(source_data).xpath('//PubmedArticle'))
  end

  def self.get_pub_by_pmid(pmid)
    pubmed_pub_hash = PubmedSourceRecord.get_pubmed_hash_for_pmid(pmid)
    unless pubmed_pub_hash.nil?
      pub = Publication.new(
        active: true,
        pmid: pmid)
      pub.build_from_pubmed_hash(pubmed_pub_hash)
      pub.sync_publication_hash_and_db
      pub.save
    end
    pub
  end

  def self.get_pubmed_hash_for_pmid(pmid)
    pubmed_source_record = get_pubmed_source_record_for_pmid(pmid)
    pubmed_source_record.source_as_hash unless pubmed_source_record.nil?
  end

  def self.get_pubmed_source_record_for_pmid(pmid)
    PubmedSourceRecord.find_by(pmid: pmid) || PubmedSourceRecord.get_pubmed_record_from_pubmed(pmid)
  end

  # @return [PubmedSourceRecord] the recently downloaded pubmed_source_records data
  def self.get_pubmed_record_from_pubmed(pmid)
    get_and_store_records_from_pubmed([pmid])
    PubmedSourceRecord.find_by(pmid: pmid)
  end

  def self.create_pubmed_source_record(pmid, pub_doc)
    PubmedSourceRecord.where(pmid: pmid).first_or_create(
      pmid: pmid,
      source_data: pub_doc.to_xml,
      is_active: true,
      source_fingerprint: Digest::SHA2.hexdigest(pub_doc))
  end

  def self.get_and_store_records_from_pubmed(pmids)
    pmidValuesForPost = pmids.collect { |pmid| "&id=#{pmid}" }.join
    the_incoming_xml = PubmedClient.new.fetch_records_for_pmid_list pmidValuesForPost

    count = 0
    source_records = []
    Nokogiri::XML(the_incoming_xml).xpath('//PubmedArticle').each do |pub_doc|
      pmid = pub_doc.xpath('MedlineCitation/PMID').text
      begin
        count += 1
        source_records << PubmedSourceRecord.new(
          pmid: pmid,
          source_data: pub_doc.to_xml,
          is_active: true,
          source_fingerprint: Digest::SHA2.hexdigest(pub_doc))
        pmids.delete(pmid)
      rescue => e
        NotificationManager.error(e, "Cannot create PubmedSourceRecord with pmid: #{pmid}", self)
      end
    end
    PubmedSourceRecord.import source_records
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

  def convert_pubmed_publication_doc_to_hash(publication)
    # MEDLINE®PubMed® XML Element Descriptions and their Attributes, see
    # https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
    record_as_hash = {}
    pmid = publication.xpath('MedlineCitation/PMID').text

    abstract = extract_abstract_from_pubmed_record(publication)
    mesh_headings = extract_mesh_headings_from_pubmed_record(publication)

    record_as_hash[:provenance] = Settings.pubmed_source
    record_as_hash[:pmid] = pmid

    record_as_hash[:title] = publication.xpath('MedlineCitation/Article/ArticleTitle').text unless publication.xpath('MedlineCitation/Article/ArticleTitle').blank?
    record_as_hash[:abstract] = abstract unless abstract.blank?

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

    record_as_hash[:mesh_headings] = mesh_headings unless mesh_headings.blank?
    record_as_hash[:year] = publication.xpath('MedlineCitation/Article/Journal/JournalIssue/PubDate/Year').text unless publication.xpath('MedlineCitation/Article/Journal/JournalIssue/PubDate/Year').blank?

    record_as_hash[:type] = Settings.sul_doc_types.article

    # record_as_hash[:publisher] =  publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
    # record_as_hash[:city] = publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
    # record_as_hash[:stateprovince] = publication.xpath('MedlineCitation/Article/').text unless publication.xpath("MedlineCitation/Article/").blank?
    record_as_hash[:country] = publication.xpath('MedlineCitation/MedlineJournalInfo/Country').text unless publication.xpath('MedlineCitation/MedlineJournalInfo/Country').blank?

    record_as_hash[:pages] = publication.xpath('MedlineCitation/Article/Pagination/MedlinePgn').text unless publication.xpath('MedlineCitation/Article/Pagination/MedlinePgn').blank?

    journal_hash = {}
    journal_hash[:name] = publication.xpath('MedlineCitation/Article/Journal/Title').text unless publication.xpath('MedlineCitation/Article/Journal/Title').blank?
    journal_hash[:volume] = publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').text unless publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').blank?
    journal_hash[:issue] = publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').text unless publication.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').blank?
    # journal_hash[:articlenumber] = publication.xpath('ArticleNumber') unless publication.xpath('ArticleNumber').blank?
    #  journal_hash[:pages] = publication.xpath('Pagination').text unless publication.xpath('Pagination').blank?
    journal_identifiers = []
    issn = publication.xpath('MedlineCitation/Article/Journal/ISSN').text
    record_as_hash[:issn] = issn unless issn.blank?
    journal_identifiers << { type: 'issn', id: issn, url: Settings.SULPUB_ID.SEARCHWORKS_URI + issn } unless issn.blank?
    journal_hash[:identifier] = journal_identifiers
    record_as_hash[:journal] = journal_hash

    record_as_hash[:identifier] = [{ type: 'PMID', id: pmid, url: "#{Settings.PUBMED.ARTICLE_BASE_URI}#{pmid}"}]
    # the DOI can be in one of two places: ArticleId or ELocationID
    doi = publication.at_xpath('//ArticleId[@IdType="doi"]')
    doi = publication.at_xpath('//ELocationID[@EIdType="doi"]') unless doi.present? && doi.text.present?
    record_as_hash[:identifier] << { type: 'doi', id: doi.text, url: "#{Settings.DOI.BASE_URI}#{doi.text}" } if doi.present? && doi.text.present?
    pmc = publication.at_xpath('//ArticleId[@IdType="pmc"]')
    record_as_hash[:identifier] << { type: 'pmc', id: pmc.text } if pmc.present? && pmc.text.present?
    record_as_hash
  end

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
    # @return author_hash [Hash] with keys :firstname, :middlename and :lastname
    def author_to_hash(author)
      # <Author> examples provide many variations at No. 20 from
      # https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
      ##
      # Ignore an empty <Author/> element
      return if author.children.empty?
      # Ignore an <Author> that contains only <CollectiveName>
      return if author.xpath('CollectiveName').present?
      # Ignore an <Author ValidYN="N"> or missing ValidYN attribute
      return if author.attributes['ValidYN'].blank? || author.attributes['ValidYN'].value == 'N'
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
      end
      if initials.length > 1
        # If there is no data from <Forename>, use this middle initial
        mn = initials[1] if mn.blank?
      end
      # Currently ignoring <Suffix> data
      author_hash = {
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
      author_hash
    end
end
