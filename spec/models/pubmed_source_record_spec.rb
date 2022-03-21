# frozen_string_literal: true

describe PubmedSourceRecord, :vcr do
  let(:pmid_created_1999) { 10_000_166 }

  def author_doc(xml)
    Nokogiri::XML(xml).at_xpath('/Author')
  end

  describe 'parses valid <Author> examples' do
    # Example <Author> records from No. 20 at https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
    let(:author_valid) do
      {
        Abrams: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Abrams</LastName> <ForeName>Judith</ForeName> <Initials>J</Initials> </Author>'),
          hash: { firstname: 'Judith', lastname: 'Abrams' }
        },
        Amara: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Amara</LastName> <ForeName>Mohamed el-Walid</ForeName> <Initials>Mel- W</Initials> </Author>'),
          hash: { firstname: 'Mohamed', middlename: 'el-Walid', lastname: 'Amara' }
        },
        Brown: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Brown</LastName> <ForeName>Canada Quincy</ForeName> <Initials>CQ</Initials> </Author>'),
          hash: { firstname: 'Canada', middlename: 'Quincy', lastname: 'Brown' }
        },
        Buncke: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Buncke</LastName> <ForeName>Gregory M</ForeName> <Initials>GM</Initials> </Author>'),
          hash: { firstname: 'Gregory', middlename: 'M', lastname: 'Buncke' }
        },
        Gonzales: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Gonzales-loza</LastName> <ForeName>María del R</ForeName> <Initials>Mdel R</Initials> </Author>'),
          hash: { firstname: 'María', middlename: 'del R', lastname: 'Gonzales-loza' }
        },
        Hauser: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Hauser</LastName> <ForeName>Michelle E</ForeName> <Initials>ME</Initials> </Author>'),
          hash: { firstname: 'Michelle', middlename: 'E', lastname: 'Hauser' }
        },
        Johnson: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Johnson</LastName> <Initials>DL</Initials> </Author>'),
          hash: { firstname: 'D', middlename: 'L', lastname: 'Johnson' }
        },
        Krylov: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Krylov</LastName> <ForeName>Iakobish K</ForeName> <Initials>IaK</Initials> </Author>'),
          hash: { firstname: 'Iakobish', middlename: 'K', lastname: 'Krylov' }
        },
        Melosh: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Melosh</LastName> <ForeName>H J</ForeName> <Suffix>3rd</Suffix> <Initials>HJ</Initials> </Author>'),
          hash: { firstname: 'H', middlename: 'J', lastname: 'Melosh' }
        },
        Todoroki: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Todoroki</LastName> <ForeName>Shin-ichi</ForeName> <Initials>S</Initials> </Author>'),
          hash: { firstname: 'Shin-ichi', lastname: 'Todoroki' }
        }
      }
    end

    def check_author_hash(author)
      author_hash = subject.send(:author_to_hash, author_valid[author][:xml])
      expect(author_hash).to eq author_valid[author][:hash]
    end
    it 'extracts names for Amara example' do
      check_author_hash(:Amara)
    end

    it 'extracts names for Abrams example' do
      check_author_hash(:Abrams)
    end

    it 'extracts names for Brown example' do
      check_author_hash(:Brown)
    end

    it 'extracts names for Buncke example' do
      check_author_hash(:Buncke)
    end

    it 'extracts names for Gonzales example' do
      check_author_hash(:Gonzales)
    end

    it 'extracts names for Hauser example' do
      check_author_hash(:Hauser)
    end

    it 'extracts names for Krylov example' do
      check_author_hash(:Krylov)
    end

    it 'extracts names for Melosh example' do
      check_author_hash(:Melosh)
    end

    it 'extracts names for Todoroki example' do
      check_author_hash(:Todoroki)
    end

    it 'parses <Author> without <ForeName> element' do
      check_author_hash(:Johnson)
    end

    it 'extracts names when ValidYN attribute is missing' do
      author = author_doc(' <Author> <LastName>Whitely</LastName> <ForeName>R J</ForeName> <Initials>RJ</Initials> </Author>')
      expect(subject.send(:author_to_hash, author)).to eq(firstname: 'R', middlename: 'J', lastname: 'Whitely')
    end
  end

  describe 'parses invalid <Author> examples' do
    # When an author name is corrected, the uncorrected form is still in the AuthorList, but flagged with ValidYN="N"
    it 'extracts nothing when ValidYN="N"' do
      author = author_doc(' <Author ValidYN="N"> <LastName>Whitely</LastName> <ForeName>R J</ForeName> <Initials>RJ</Initials> </Author>')
      expect(subject.send(:author_to_hash, author)).to be_nil
    end

    it 'extracts nothing for CollectiveName' do
      author = author_doc(' <Author ValidYN="Y"> <CollectiveName>SBU-group. Swedish Council of Technology Assessment in Health Care</CollectiveName> </Author>')
      expect(subject.send(:author_to_hash, author)).to be_nil
    end
  end

  describe '.get_pubmed_record_from_pubmed' do
    it 'returns an instance of PubmedSourceRecord' do
      record = described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
      expect(record).to be_an described_class
    end

    it 'returns nil if pubmed lookup is disabled' do
      allow(Settings.PUBMED).to receive(:lookup_enabled).and_return(false)
      record = described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
      expect(record).to be_nil
    end

    it 'calls PubmedSourceRecord.get_and_store_records_from_pubmed' do
      expect(described_class).to receive(:get_and_store_records_from_pubmed)
      described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
    end

    it 'extracts fields - pmid' do
      record = described_class.send(:get_pubmed_record_from_pubmed, pmid_created_1999)
      expect(record.pmid).to eq pmid_created_1999
    end
  end

  describe '.source_as_hash' do
    it 'parses the year correctly' do
      # fixture records
      record = create :pubmed_source_record_10000166 # year in first location
      expect(record.source_as_hash[:year]).to eq '1992'
      record = create :pubmed_source_record_29279863 # year in alternate location
      expect(record.source_as_hash[:year]).to eq '2017'
      record = create :pubmed_source_record_23388678 # year in another alternate location
      expect(record.source_as_hash[:year]).to eq '2013'
    end

    it 'sets the year to nil when not found' do
      # manual test data
      source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
      record = described_class.create(pmid: pmid_created_1999, source_data: source_data)
      expect(record.source_as_hash[:year]).to be_nil # no year
    end

    it 'ignores an invalid year' do
      source_data =
        <<-XML
          <PubmedArticle>
          <PubmedData>
          <History>
            <PubMedPubDate PubStatus="received">
              <Year>2017</Year>
              <Month>11</Month>
              <Day>16</Day>
            </PubMedPubDate>
            <PubMedPubDate PubStatus="accepted">
                <Year>Bogus</Year>
                <Month>12</Month>
            </PubMedPubDate>
          </PubmedArticle>
        XML
      record = described_class.create(pmid: pmid_created_1999, source_data: source_data)
      expect(record.source_as_hash[:year]).to be_nil # bogus is not a valid year
    end

    xit 'parses the date correctly' do
      # fixture records
      record = create :pubmed_source_record_10000166 # date
      expect(record.source_as_hash[:date]).to eq '1992-02-05'
      record = create :pubmed_source_record_29279863 # another date
      expect(record.source_as_hash[:date]).to eq '2017-12-22'
      record = create :pubmed_source_record_23388678 # another date
      expect(record.source_as_hash[:date]).to eq '2013-02-08'
    end

    xit 'sets the date to nil when not found' do
      # manual test data
      source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
      record = described_class.create(pmid: pmid_created_1999, source_data: source_data)
      expect(record.source_as_hash[:date]).to be_nil # no date
    end

    xit 'ignores the day when not found' do
      source_data =
        <<-XML
          <PubmedArticle>
          <PubmedData>
          <History>
            <PubMedPubDate PubStatus="received">
              <Year>2017</Year>
              <Month>11</Month>
              <Day>16</Day>
            </PubMedPubDate>
            <PubMedPubDate PubStatus="accepted">
                <Year>2017</Year>
                <Month>5</Month>
            </PubMedPubDate>
          </PubmedArticle>
        XML
      record = described_class.create(pmid: pmid_created_1999, source_data: source_data)
      expect(record.source_as_hash[:date]).to eq '2017-05' # no day in one of the acceptable date paths, it zero pads the month
    end

    xit 'handles a month as an abbreviation' do
      source_data =
        <<-XML
          <PubmedArticle>
          <PubmedData>
          <History>
            <PubMedPubDate PubStatus="received">
              <Year>2017</Year>
              <Month>11</Month>
              <Day>16</Day>
            </PubMedPubDate>
            <PubMedPubDate PubStatus="accepted">
                <Year>2017</Year>
                <Month>Mar</Month>
                <Day>5</Day>
            </PubMedPubDate>
          </PubmedArticle>
        XML
      record = described_class.create(pmid: pmid_created_1999, source_data: source_data)
      expect(record.source_as_hash[:date]).to eq '2017-03-05' # convert Mar to 03 and zero pads the day
    end
  end

  describe '.pubmed_update' do
    it 'updates the :source_data field' do
      source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
      new_source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><SomeNewData/></PubmedArticle>'
      pubmed_record = described_class.create(pmid: pmid_created_1999, source_data: source_data)
      allow(described_class).to receive(:find_by_pmid).with(pmid_created_1999).and_return(pubmed_record)
      expect(pubmed_record.source_data).to be_equivalent_to source_data
      allow_any_instance_of(Pubmed::Client).to receive(:fetch_records_for_pmid_list).with(pmid_created_1999).and_return(new_source_data)
      expect(pubmed_record.pubmed_update).to be true
      expect(pubmed_record.source_data).to be_equivalent_to new_source_data
    end

    it 'does not update the :source_data field if no pubmed record is found' do
      source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
      new_source_data = '<?xml version="1.0" ?><!DOCTYPE PubmedArticleSet PUBLIC "-//NLM//DTD PubMedArticle, 1st January 2017//EN" "https://dtd.nlm.nih.gov/ncbi/pubmed/out/pubmed_170101.dtd"><PubmedArticleSet></PubmedArticleSet>'
      pubmed_record = described_class.create(pmid: pmid_created_1999, source_data: source_data)
      allow(described_class).to receive(:find_by_pmid).with(pmid_created_1999).and_return(pubmed_record)
      expect(pubmed_record.source_data).to be_equivalent_to source_data
      allow_any_instance_of(Pubmed::Client).to receive(:fetch_records_for_pmid_list).with(pmid_created_1999).and_return(new_source_data)
      expect(pubmed_record.pubmed_update).to be false
      expect(pubmed_record.source_data).to be_equivalent_to source_data
    end
  end

  describe '.source_as_hash' do
    context 'DOI extraction' do
      def doi(pmid)
        record = described_class.send(:get_pubmed_record_from_pubmed, pmid)
        return nil if record.nil?

        record.source_as_hash[:identifier].find { |id| id[:type] == 'doi' }
      end
      it 'constructs a URL based on the DOI' do
        expect(doi(12_529_422)).to include(url: 'https://doi.org/10.1091/mbc.e02-06-0327')
      end

      context 'extracts from ArticleId' do
        it 'works when ELocationID is missing' do
          expect(doi(12_529_422)).to include(id: '10.1091/mbc.e02-06-0327')
        end

        it 'works when ELocationID is present' do
          expect(doi(23_453_302)).to include(id: '10.1016/j.neunet.2013.01.016')
        end

        it 'works when record is longer than 64kb' do
          expect(doi(26_430_984)).to include(id: '10.1103/PhysRevLett.115.121604')
        end
      end

      context 'extracts from ELocationID' do
        it 'works when ArticleId is missing' do
          expect(doi(26_858_277)).to include(id: '10.1136/bmj.i493')
        end
      end
    end
  end
end
