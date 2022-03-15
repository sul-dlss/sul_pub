# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Pubmed
  # Map Pubmed source record data into the SUL PubHash data
  class MapPubHash
    attr_reader :pubmed_article

    # @param source_data [PubmedSourceRecord.source_data]
    def initialize(source_data)
      @pubmed_article = Nokogiri::XML(source_data).xpath('//PubmedArticle')
    end

    def self.map(source_data)
      new(source_data).pub_hash
    end

    # Convert MEDLINE®PubMed® XML to pub_hash
    # @return [Hash<Symbol => Object>] pub_hash
    # @see https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html XML Element Descriptions and their Attributes
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def pub_hash
      pub_hash = {}

      pmid = pubmed_article.xpath('MedlineCitation/PMID').text

      abstract = extract_abstract_from_pubmed_record
      mesh_headings = extract_mesh_headings_from_pubmed_record

      pub_hash[:provenance] = Settings.pubmed_source
      pub_hash[:pmid] = pmid

      if pubmed_article.xpath('MedlineCitation/Article/ArticleTitle').present?
        pub_hash[:title] = pubmed_article.xpath('MedlineCitation/Article/ArticleTitle').text
      end
      pub_hash[:abstract] = abstract if abstract.present?

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
      author_list = pubmed_article.xpath('MedlineCitation/Article/AuthorList/Author')
      pub_hash[:author] = author_list.map { |a| author_to_hash(a) }.compact

      pub_hash[:mesh_headings] = mesh_headings if mesh_headings.present?

      year = extract_year_from_pubmed_record
      pub_hash[:year] = year if year

      month = extract_month_from_pubmed_record
      day = extract_day_from_pubmed_record
      if year && month && day
        pub_hash[:date] =  "#{year}-#{month.rjust(2, '0')}-#{day.rjust(2, '0')}"
      elsif year && month
        pub_hash[:date] =  "#{year}-#{month.rjust(2, '0')}"
      end

      pub_hash[:type] = Settings.sul_doc_types.article

      if pubmed_article.xpath('MedlineCitation/MedlineJournalInfo/Country').present?
        pub_hash[:country] =
          pubmed_article.xpath('MedlineCitation/MedlineJournalInfo/Country').text
      end

      if pubmed_article.xpath('MedlineCitation/Article/Pagination/MedlinePgn').present?
        pub_hash[:pages] =
          pubmed_article.xpath('MedlineCitation/Article/Pagination/MedlinePgn').text
      end

      journal_hash = {}
      if pubmed_article.xpath('MedlineCitation/Article/Journal/Title').present?
        journal_hash[:name] =
          pubmed_article.xpath('MedlineCitation/Article/Journal/Title').text
      end
      if pubmed_article.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').present?
        journal_hash[:volume] =
          pubmed_article.xpath('MedlineCitation/Article/Journal/JournalIssue/Volume').text
      end
      if pubmed_article.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').present?
        journal_hash[:issue] =
          pubmed_article.xpath('MedlineCitation/Article/Journal/JournalIssue/Issue').text
      end
      journal_identifiers = []
      issn = pubmed_article.xpath('MedlineCitation/Article/Journal/ISSN').text
      pub_hash[:issn] = issn if issn.present?
      journal_identifiers << { type: 'issn', id: issn, url: Settings.SULPUB_ID.SEARCHWORKS_URI + issn } if issn.present?
      journal_hash[:identifier] = journal_identifiers
      pub_hash[:journal] = journal_hash

      pub_hash[:identifier] = [{ type: 'PMID', id: pmid, url: "#{Settings.PUBMED.ARTICLE_BASE_URI}#{pmid}" }]
      # the DOI can be in one of two places: ArticleId or ELocationID
      doi = pubmed_article.at_xpath('//ArticleId[@IdType="doi"]')
      doi = pubmed_article.at_xpath('//ELocationID[@EIdType="doi"]') unless doi.present? && doi.text.present?
      if doi.present? && doi.text.present?
        pub_hash[:identifier] << { type: 'doi', id: doi.text,
                                   url: "#{Settings.DOI.BASE_URI}#{doi.text}" }
      end
      pmc = pubmed_article.at_xpath('//ArticleId[@IdType="pmc"]')
      pub_hash[:identifier] << { type: 'pmc', id: pmc.text } if pmc.present? && pmc.text.present?
      pub_hash
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    private

    def extract_abstract_from_pubmed_record
      pubmed_article.xpath('MedlineCitation/Article/Abstract/AbstractText').text
    end

    def extract_mesh_headings_from_pubmed_record
      mesh_headings_for_record = []
      pubmed_article.xpath('MedlineCitation/MeshHeadingList/MeshHeading').each do |mesh_heading|
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

    # see https://dtd.nlm.nih.gov/ncbi/pubmed/doc/out/180101/el-Year.html
    def extract_year_from_pubmed_record
      # look for a year in all of the xpath locations in order, pick the first that produces something that looks like a four digit year
      pubmed_date_xpaths('Year')
        .map { |path| pubmed_article.xpath(path).text.match(/[12][0-9]{3}/).to_s }
        .compact_blank.first
    end

    # see https://dtd.nlm.nih.gov/ncbi/pubmed/doc/out/180101/el-Month.html
    def extract_month_from_pubmed_record
      # look for a month in all of the xpath locations in order
      #  pick the first that produces something that looks like a month (12 or Aug)
      pubmed_date_xpaths('Month').map do |path|
        month_value = pubmed_article.xpath(path).text
        match = month_value.match(/\A[012]?[0-9]{1}\z/) # e.g. 01, 11, 06, 6, 12
        name_match = month_value.match(/\A[a-zA-Z]{3}\z/) # e.g. Aug, aug, Oct
        match = Date::ABBR_MONTHNAMES.index(name_match.to_s) if name_match # convert month name to number
        match.to_s
      end.compact_blank.first
    end

    # see https://dtd.nlm.nih.gov/ncbi/pubmed/doc/out/180101/el-Day.html
    def extract_day_from_pubmed_record
      # look for a day in all of the xpath locations in order
      #  pick the first that produces something that looks like a day
      pubmed_date_xpaths('Day').map do |path|
        day_value = pubmed_article.xpath(path).text
        match = day_value.match(/\A[0123]?[0-9]{1}\z/) # e.g. 01, 11, 06, 6, 12, 23, 30
        match.to_s
      end.compact_blank.first
    end

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
      }.compact
      # TODO: extract Identifier
      # <Identifier> was added to <AuthorList> with the 2010 DTD, but was not used until 2013.
      # <Identifier Source="ORCID">0000000179841889</Identifier>
      ##
      # TODO: extract Affiliation
      # <AffiliationInfo> was added to <AuthorList> with the 2015 DTD.
      # The <AffiliationInfo> envelope element includes <Affliliation> and <Identifier>.
    end

    # see https://dtd.nlm.nih.gov/ncbi/pubmed/doc/out/180101/el-PubDate.html for PubDate definition
    # and https://dtd.nlm.nih.gov/ncbi/pubmed/doc/out/180101/att-PubStatus.html for PubStatus type definitions
    # and https://dtd.nlm.nih.gov/ncbi/pubmed/doc/out/180101/el-JournalIssue.html for the JournalIssue definition
    # and https://dtd.nlm.nih.gov/ncbi/pubmed/doc/out/180101/el-ArticleDate.html for the ArticleDate definition
    def pubmed_date_xpaths(date_part)
      [
        "MedlineCitation/Article/Journal/JournalIssue/PubDate/#{date_part}",
        "MedlineCitation/Article/ArticleDate/#{date_part}",
        "PubmedData/History/PubMedPubDate[@PubStatus='accepted']/#{date_part}",
        "PubmedData/History/PubMedPubDate[@PubStatus='pubmed']/#{date_part}",
        "PubmedData/History/PubMedPubDate[@PubStatus='medline']/#{date_part}",
        "PubmedData/History/PubMedPubDate[@PubStatus='entrez']/#{date_part}"
      ]
    end
  end
end
# rubocop:enable Metrics/ClassLength
