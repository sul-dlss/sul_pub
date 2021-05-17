# frozen_string_literal: true

describe ScienceWirePublication do
  let(:wrong_element) do
    xml_doc = Nokogiri::XML '<NotPublicationItem/>'
    xml_doc.xpath('NotPublicationItem').first
  end

  let(:publication_item_empty) do
    xml_doc = Nokogiri::XML '<PublicationItem/>'
    xml_doc.xpath('PublicationItem').first
  end

  let(:publication_item_xml) do
    File.read Rails.root.join('spec/fixtures/sciencewire_source_record/publication_item.xml')
  end
  let(:publication_item_doc) { Nokogiri::XML publication_item_xml }
  let(:publication_item_element) { publication_item_doc.xpath('PublicationItem').first }

  let(:subject) do
    described_class.new(publication_item_element)
  end

  describe '#initialize' do
    it 'accepts a Nokogiri::XML::Element' do
      expect(subject.xml_doc).to be_an Nokogiri::XML::Element
    end

    it 'sets @xml_doc to be the first <PublicationItem> element' do
      pub = described_class.new(publication_item_element)
      item = pub.instance_variable_get('@xml_doc')
      expect(item).to be_an Nokogiri::XML::Element
      expect(item.name).to eq 'PublicationItem'
    end

    it 'raises ArgumentError unless given a <PublicationItem> Nokogiri::XML::Element' do
      expect { described_class.new(wrong_element) }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError unless given a Nokogiri::XML::Element' do
      expect { described_class.new('') }.to raise_error(ArgumentError)
    end
  end

  # ------------------------------------------------------------
  # Publication Identifiers

  describe '#doi' do
    it 'returns a String' do
      expect(subject.doi).to be_an String
    end

    it 'returns a valid DOI' do
      expect(subject.doi).to eq '10.1038/447638a'
    end
  end

  describe '#issn' do
    it 'returns a String' do
      expect(subject.issn).to be_an String
    end

    it 'returns a valid ISSN' do
      expect(subject.issn).to eq '0016-5085'
    end
  end

  describe '#isbn' do
    it 'returns a String' do
      expect(subject.isbn).to be_an String
    end

    it 'returns a valid ISBN' do
      expect(subject.isbn).to eq '' # there isn't one for this fixture
    end
  end

  describe '#publication_item_id' do
    it 'returns a Integer' do
      expect(subject.publication_item_id).to be_an Integer
    end

    it 'returns a valid Integer' do
      expect(subject.publication_item_id).to eq 75_299_710
    end
  end

  describe '#pmid' do
    it 'returns a Integer' do
      expect(subject.pmid).to be_an Integer
    end

    it 'returns a valid Integer' do
      expect(subject.pmid).to eq 99_999_999
    end
  end

  describe '#wos_item_id' do
    it 'returns a String' do
      expect(subject.wos_item_id).to be_an String
    end

    it 'returns a valid WoSItemID' do
      expect(subject.wos_item_id).to eq '000371236403656'
    end
  end

  describe '#obsolete?' do
    it 'returns true when <IsObsolete> is "true"' do
      xml_doc = subject.xml_doc
      xml_doc.at_xpath('//PublicationItem/IsObsolete').children = 'true'
      expect(subject.obsolete?).to be true
    end

    it 'returns false when <IsObsolete> is "false"' do
      xml_doc = subject.xml_doc
      xml_doc.at_xpath('//PublicationItem/IsObsolete').children = 'false'
      expect(subject.obsolete?).to be false
    end
  end

  describe '#new_publication_item_id' do
    it 'returns a Integer' do
      expect(subject.new_publication_item_id).to be_an Integer
    end

    it 'returns a valid Integer' do
      expect(subject.new_publication_item_id).to eq 0 # for this fixture
    end
  end

  # ------------------------------------------------------------
  # Publication title and abstract

  describe '#title' do
    it 'returns a String' do
      expect(subject.title).to be_an String
    end

    it 'returns a valid Title' do
      expect(subject.title).to eq 'PKD1-Mediates Class Iia Histone Deacetylase Phosphorylation and Nuclear/Cytoplasmic Shuttling in Intestinal Epithelial Cells'
    end
  end

  describe '#abstract' do
    it 'returns a String' do
      expect(subject.abstract).to be_an String
    end

    it 'returns a valid Abstract' do
      expect(subject.abstract).to eq '' # it's empty for this fixture
    end
  end

  # ------------------------------------------------------------
  # Authors

  context 'Authors' do
    let(:author_list) { publication_item_doc.at_xpath('//PublicationItem/AuthorList').text }
    let(:authors) { author_list.split('|') }
    let(:author_hashes) do
      authors.map do |name|
        ln, fn, mn = name.split(',')
        { lastname: ln, firstname: fn, middlename: mn }
      end
    end

    describe '#authors' do
      it 'returns an Array<String>' do
        expect(subject.authors).to be_an Array
        expect(subject.authors.first).to be_an String
      end

      it 'returns a valid array of authors' do
        expect(subject.authors).to eq authors
      end
    end

    describe '#author_count' do
      it 'returns an Integer' do
        expect(subject.author_count).to be_an Integer
      end

      it 'returns a valid AuthorCount' do
        expect(subject.author_count).to eq 5
      end
    end

    describe '#author_list' do
      it 'returns a String' do
        expect(subject.author_list).to be_an String
      end

      it 'returns a valid AuthorList' do
        expect(subject.author_list).to eq author_list
      end
    end

    describe '#author_names' do
      it 'returns an Array<Hash>' do
        expect(subject.author_names).to be_an Array
        expect(subject.author_names.first).to be_an Hash
      end

      it 'returns a valid array of author names Hashes' do
        expect(subject.author_names).to eq author_hashes
      end
    end
  end

  # ------------------------------------------------------------
  # Keywords

  context 'Keywords' do
    let(:keyword_list) { publication_item_doc.at_xpath('//PublicationItem/KeywordList').text }
    let(:keywords) { keyword_list.split('|') }

    describe '#keywords' do
      it 'returns an Array<String>' do
        expect(subject.keywords).to be_an Array
        expect(subject.keywords.first).to be_an String
      end

      it 'returns a valid array of keywords' do
        expect(subject.keywords).to eq keywords
      end
    end

    describe '#keyword_list' do
      it 'returns a String' do
        expect(subject.keyword_list).to be_an String
      end

      it 'returns a valid KeywordList' do
        expect(subject.keyword_list).to eq keyword_list
      end
    end
  end

  # ------------------------------------------------------------
  # Publication Types and Categories

  describe '#document_category' do
    it 'returns a String' do
      expect(subject.document_category).to be_an String
    end

    it 'returns a valid DocumentTypeList' do
      expect(subject.document_category).to eq 'Conference Proceeding Document'
    end
  end

  describe '#document_type_list' do
    it 'returns a String' do
      expect(subject.document_type_list).to be_an String
    end

    it 'returns a valid DocumentTypeList' do
      expect(subject.document_type_list).to include 'Journal Article' # for this fixture
    end
  end

  describe '#document_types' do
    it 'returns an Array<String>' do
      expect(subject.document_types).to be_an Array
      expect(subject.document_types.first).to be_an String
    end

    it 'returns a valid DocumentTypeList Array' do
      expect(subject.document_types).to include 'Journal Article' # for this fixture
    end
  end

  describe '#doc_type?' do
    it 'returns true given an Array of matching DocumentType values' do
      expect(subject.doc_type?(['Journal Article'])).to be true
    end

    it 'returns false given an Array of non-matching DocumentType values' do
      expect(subject.doc_type?(['NoDocTypeMatch'])).to be false
    end

    it 'returns false given an empty Array' do
      expect(subject.doc_type?([])).to be false
    end
  end

  describe '#publication_type' do
    it 'returns a String' do
      expect(subject.publication_type).to be_an String
    end

    it 'returns a valid PublicationType' do
      expect(subject.publication_type).to eq 'Journal'
    end
  end

  # # @return [String] PublicationSubjectCategoryList
  # def publication_subject_category_list
  #   element_text 'PublicationSubjectCategoryList'
  # end
  describe '#publication_subject_category_list' do
    it 'returns a String' do
      expect(subject.publication_subject_category_list).to be_an String
    end

    it 'returns a valid PublicationSubjectCategoryList' do
      expect(subject.publication_subject_category_list).to eq 'Gastroenterology & Hepatology'
    end
  end

  # ------------------------------------------------------------
  # Publication Dates

  describe '#publication_date' do
    it 'returns a String' do
      expect(subject.publication_date).to be_an String
    end

    it 'returns a valid PublicationDate' do
      expect(subject.publication_date).to eq '2014-05-01T00:00:00'
    end
  end

  describe '#publication_year' do
    it 'returns a Integer' do
      expect(subject.publication_year).to be_an Integer
    end

    it 'returns a valid PublicationYear' do
      expect(subject.publication_year).to eq 2014
    end
  end

  # ------------------------------------------------------------
  # Journal or Series Information

  describe '#article_number' do
    it 'returns a String' do
      expect(subject.article_number).to be_an String
    end

    it 'returns a valid ArticleNumber' do
      expect(subject.article_number).to eq '' # it's not present in this fixture
    end
  end

  describe '#publication_source_title' do
    it 'returns a String' do
      expect(subject.publication_source_title).to be_an String
    end

    it 'returns a valid PublicationSourceTitle' do
      expect(subject.publication_source_title).to eq 'GASTROENTEROLOGY'
    end
  end

  describe '#volume' do
    it 'returns a String' do
      expect(subject.volume).to be_an String
    end

    it 'returns a valid Volume' do
      expect(subject.volume).to eq '146'
    end
  end

  describe '#issue' do
    it 'returns a String' do
      expect(subject.issue).to be_an String
    end

    it 'returns a valid Issue' do
      expect(subject.issue).to eq '5'
    end
  end

  describe '#pagination' do
    it 'returns a String' do
      expect(subject.pagination).to be_an String
    end

    it 'returns a valid Pagination' do
      expect(subject.pagination).to eq 'S785-S785'
    end
  end

  # ------------------------------------------------------------
  # Conference Information

  describe '#conference_title' do
    it 'returns a String' do
      expect(subject.conference_title).to be_an String
    end

    it 'returns a valid ConferenceTitle' do
      expect(subject.conference_title).to eq '55th Annual Meeting of the Society-for-Surgery-of-the-Alimentary-Tract (SSAT) / Digestive Disease Week (DDW)'
    end
  end

  describe '#conference_city' do
    it 'returns a String' do
      expect(subject.conference_city).to be_an String
    end

    it 'returns a valid ConferenceCity' do
      expect(subject.conference_city).to eq 'CHICAGO'
    end
  end

  describe '#conference_state_country' do
    it 'returns a String' do
      expect(subject.conference_state_country).to be_an String
    end

    it 'returns a valid ConferenceStateCountry' do
      expect(subject.conference_state_country).to eq 'IL'
    end
  end

  describe '#conference_start_date' do
    it 'returns a String' do
      expect(subject.conference_start_date).to be_an String
    end

    it 'returns a valid ConferenceStartDate' do
      expect(subject.conference_start_date).to eq '2014-05-03T00:00:00'
    end
  end

  describe '#conference_end_date' do
    it 'returns a String' do
      expect(subject.conference_end_date).to be_an String
    end

    it 'returns a valid ConferenceEndDate' do
      expect(subject.conference_end_date).to eq '2014-05-06T00:00:00'
    end
  end

  # ------------------------------------------------------------
  # Copyright Information

  describe '#copyright_publisher' do
    it 'returns a String' do
      expect(subject.copyright_publisher).to be_an String
    end

    it 'returns a valid CopyrightPublisher' do
      expect(subject.copyright_publisher).to eq 'W B SAUNDERS CO-ELSEVIER INC'
    end
  end

  describe '#copyright_city' do
    it 'returns a String' do
      expect(subject.copyright_city).to be_an String
    end

    it 'returns a valid CopyrightCity' do
      expect(subject.copyright_city).to eq 'PHILADELPHIA'
    end
  end

  describe '#copyright_state_province' do
    it 'returns a String' do
      expect(subject.copyright_state_province).to be_an String
    end

    it 'returns a valid CopyrightStateProvince' do
      expect(subject.copyright_state_province).to eq 'PA'
    end
  end

  describe '#copyright_country' do
    it 'returns a String' do
      expect(subject.copyright_country).to be_an String
    end

    it 'returns a valid CopyrightStateProvince' do
      expect(subject.copyright_country).to eq 'UNITED STATES'
    end
  end

  # ------------------------------------------------------------
  # Bibliographic Statistics

  describe '#number_of_references' do
    it 'returns a Integer' do
      expect(subject.number_of_references).to be_an Integer
    end

    it 'returns a valid NumberOfReferences' do
      expect(subject.number_of_references).to eq 0 # it's empty for this fixture
    end
  end

  describe '#times_cited' do
    it 'returns a Integer' do
      expect(subject.times_cited).to be_an Integer
    end

    it 'returns a valid TimesCited' do
      expect(subject.times_cited).to eq 0
    end
  end

  describe '#times_not_self_cited' do
    it 'returns a Integer' do
      expect(subject.times_not_self_cited).to be_an Integer
    end

    it 'returns a valid TimesNotSelfCited' do
      expect(subject.times_not_self_cited).to eq 0
    end
  end

  # ------------------------------------------------------------
  # Search Ranks

  describe '#normalized_rank' do
    it 'returns a Integer' do
      expect(subject.normalized_rank).to be_an Integer
    end

    it 'returns a valid NormalizedRank' do
      expect(subject.normalized_rank).to eq 50
    end
  end

  describe '#ordinal_rank' do
    it 'returns a Integer' do
      expect(subject.ordinal_rank).to be_an Integer
    end

    it 'returns a valid OrdinalRank' do
      expect(subject.ordinal_rank).to eq 30
    end
  end

  describe '#rank' do
    it 'returns a Integer' do
      expect(subject.rank).to be_an Integer
    end

    it 'returns a valid Rank' do
      expect(subject.rank).to eq 216
    end
  end

  # ------------------------------------------------------------

  describe 'Nokogiri cross-checks' do
    it 'has a name matching "PublicationItem"' do
      expect(subject.xml_doc.name).to eq 'PublicationItem'
    end
  end

  describe 'sorting' do
    it 'sorts by publication_item_id' do
      xml_docA = Nokogiri::XML publication_item_xml
      xml_docB = Nokogiri::XML publication_item_xml
      elementA = xml_docA.xpath('PublicationItem').first
      elementB = xml_docB.xpath('PublicationItem').first
      pubA = described_class.new(elementA)
      pubB = described_class.new(elementB)
      elementB.at_xpath('PublicationItemID').children = (pubB.publication_item_id + 1).to_s
      expect([pubB, pubA].sort).to eq [pubA, pubB]
      ids_before = [pubB, pubA].map(&:publication_item_id)
      ids_sorted = [pubB, pubA].sort.map(&:publication_item_id)
      expect(ids_before).to eq [75_299_711, 75_299_710]
      expect(ids_sorted).to eq [75_299_710, 75_299_711]
    end
  end

  describe '#valid?' do
    it 'is true for a Nokogiri::XML::Element that is a <PublicationItem> element' do
      expect(subject.valid?).to be true
    end

    it 'is true for a Nokogiri::XML::Element that is an empty <PublicationItem> element' do
      pub = described_class.new(publication_item_empty)
      expect(pub.valid?).to be true
    end
  end
end
