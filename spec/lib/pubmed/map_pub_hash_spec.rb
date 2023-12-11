# frozen_string_literal: true

describe Pubmed::MapPubHash, :vcr do
  describe '#author_to_hash' do
    subject(:mapper) { described_class.new(source_data) }

    let(:source_data) { '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>' }
    let(:author_xml) { Nokogiri::XML(xml).at_xpath('/Author') }

    context 'parses valid <Author> examples' do
      # Example <Author> records from No. 20 at https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
      let(:author_valid) do
        {
          Abrams: {
            xml: ' <Author ValidYN="Y"> <LastName>Abrams</LastName> <ForeName>Judith</ForeName> <Initials>J</Initials> </Author>',
            hash: { firstname: 'Judith', lastname: 'Abrams' }
          },
          Amara: {
            xml: ' <Author ValidYN="Y"> <LastName>Amara</LastName> <ForeName>Mohamed el-Walid</ForeName> <Initials>Mel- W</Initials> </Author>',
            hash: { firstname: 'Mohamed', middlename: 'el-Walid', lastname: 'Amara' }
          },
          Brown: {
            xml: ' <Author ValidYN="Y"> <LastName>Brown</LastName> <ForeName>Canada Quincy</ForeName> <Initials>CQ</Initials> </Author>',
            hash: { firstname: 'Canada', middlename: 'Quincy', lastname: 'Brown' }
          },
          Buncke: {
            xml: ' <Author ValidYN="Y"> <LastName>Buncke</LastName> <ForeName>Gregory M</ForeName> <Initials>GM</Initials> </Author>',
            hash: { firstname: 'Gregory', middlename: 'M', lastname: 'Buncke' }
          },
          Gonzales: {
            xml: ' <Author ValidYN="Y"> <LastName>Gonzales-loza</LastName> <ForeName>María del R</ForeName> <Initials>Mdel R</Initials> </Author>',
            hash: { firstname: 'María', middlename: 'del R', lastname: 'Gonzales-loza' }
          },
          Hauser: {
            xml: ' <Author ValidYN="Y"> <LastName>Hauser</LastName> <ForeName>Michelle E</ForeName> <Initials>ME</Initials> </Author>',
            hash: { firstname: 'Michelle', middlename: 'E', lastname: 'Hauser' }
          },
          Johnson: {
            xml: ' <Author ValidYN="Y"> <LastName>Johnson</LastName> <Initials>DL</Initials> </Author>',
            hash: { firstname: 'D', middlename: 'L', lastname: 'Johnson' }
          },
          Krylov: {
            xml: ' <Author ValidYN="Y"> <LastName>Krylov</LastName> <ForeName>Iakobish K</ForeName> <Initials>IaK</Initials> </Author>',
            hash: { firstname: 'Iakobish', middlename: 'K', lastname: 'Krylov' }
          },
          Melosh: {
            xml: ' <Author ValidYN="Y"> <LastName>Melosh</LastName> <ForeName>H J</ForeName> <Suffix>3rd</Suffix> <Initials>HJ</Initials> </Author>',
            hash: { firstname: 'H', middlename: 'J', lastname: 'Melosh' }
          },
          Todoroki: {
            xml: ' <Author ValidYN="Y"> <LastName>Todoroki</LastName> <ForeName>Shin-ichi</ForeName> <Initials>S</Initials> </Author>',
            hash: { firstname: 'Shin-ichi', lastname: 'Todoroki' }
          }
        }
      end

      it 'extracts all names correctly' do
        author_valid.each_value do |author|
          author_xml = Nokogiri::XML(author[:xml]).at_xpath('/Author')
          author_hash = mapper.send(:author_to_hash, author_xml)
          expect(author_hash).to eq author[:hash]
        end
      end

      context 'when ValidYN attribute is missing' do
        let(:xml) { ' <Author> <LastName>Whitely</LastName> <ForeName>R J</ForeName> <Initials>RJ</Initials> </Author>' }

        it 'extracts names' do
          expect(mapper.send(:author_to_hash, author_xml)).to eq(firstname: 'R', middlename: 'J', lastname: 'Whitely')
        end
      end
    end

    context 'parses invalid <Author> examples' do
      # When an author name is corrected, the uncorrected form is still in the AuthorList, but flagged with ValidYN="N"

      context 'when when ValidYN="N"' do
        let(:xml) { ' <Author ValidYN="N"> <LastName>Whitely</LastName> <ForeName>R J</ForeName> <Initials>RJ</Initials> </Author>' }

        it 'extracts nothing' do
          expect(mapper.send(:author_to_hash, author_xml)).to be_nil
        end
      end
    end

    context 'when CollectiveName' do
      let(:xml) { ' <Author ValidYN="Y"> <CollectiveName>SBU-group. Swedish Council of Technology Assessment in Health Care</CollectiveName> </Author>' }

      it 'extracts nothing' do
        expect(mapper.send(:author_to_hash, author_xml)).to be_nil
      end
    end
  end

  describe '#source_as_hash' do
    let(:pmid_created_1999) { 10_000_166 }

    context 'when year and date extraction' do
      it 'parses the year correctly' do
        # fixture records
        record = create(:pubmed_source_record_10000166) # year in first location
        expect(described_class.new(record.source_data).pub_hash[:year]).to eq '1992'
        record = create(:pubmed_source_record_29279863) # year in alternate location
        expect(described_class.new(record.source_data).pub_hash[:year]).to eq '2017'
        record = create(:pubmed_source_record_23388678) # year in another alternate location
        expect(described_class.new(record.source_data).pub_hash[:year]).to eq '2013'
      end

      it 'sets the year to nil when not found' do
        # manual test data
        source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
        expect(described_class.new(source_data).pub_hash[:year]).to be_nil # no year
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
        expect(described_class.new(source_data).pub_hash[:year]).to be_nil # bogus is not a valid year
      end

      it 'parses the date correctly' do
        # fixture records
        record = create(:pubmed_source_record_10000166) # date
        expect(described_class.new(record.source_data).pub_hash[:date]).to eq '1992-02-05'
        record = create(:pubmed_source_record_29279863) # another date
        expect(described_class.new(record.source_data).pub_hash[:date]).to eq '2017-12-22'
        record = create(:pubmed_source_record_23388678) # another date
        expect(described_class.new(record.source_data).pub_hash[:date]).to eq '2013-02-08'
      end

      # rubocop:disable RSpec/ExampleLength
      it 'parses the date correctly when day is not provided in preferred location but is later' do
        # manual test data
        source_data = <<-XML
            <PubmedArticle>
              <MedlineCitation Status="Publisher" Owner="NLM">
                  <PMID Version="1">11096574</PMID>
                  <DateCreated>
                      <Year>2000</Year>
                      <Month>11</Month>
                      <Day>29</Day>
                  </DateCreated>
                  <Article PubModel="Print">
                      <Journal>
                          <ISSN IssnType="Print">1092-8472</ISSN>
                          <JournalIssue CitedMedium="Print">
                              <Volume>2</Volume>
                              <Issue>1</Issue>
                              <PubDate>
                                  <Year>1999</Year>
                                  <Month>Feb</Month>
                              </PubDate>
                          </JournalIssue>
                          <Title>Current treatment options in gastroenterology</Title>
                          <ISOAbbreviation>Curr Treat Options Gastroenterol</ISOAbbreviation>
                      </Journal>
                      <ArticleTitle>Variceal Bleeding.</ArticleTitle>
                      <Pagination>
                          <MedlinePgn>61-67</MedlinePgn>
                      </Pagination>
                  </Article>
              </MedlineCitation>
              <PubmedData>
                  <History>
                      <PubMedPubDate PubStatus="pubmed">
                          <Year>2000</Year>
                          <Month>11</Month>
                          <Day>30</Day>
                      </PubMedPubDate>
                      <PubMedPubDate PubStatus="medline">
                          <Year>2000</Year>
                          <Month>11</Month>
                          <Day>30</Day>
                      </PubMedPubDate>
                      <PubMedPubDate PubStatus="entrez">
                          <Year>2000</Year>
                          <Month>11</Month>
                          <Day>30</Day>
                          <Hour>0</Hour>
                          <Minute>0</Minute>
                      </PubMedPubDate>
                  </History>
                  <PublicationStatus>ppublish</PublicationStatus>
              </PubmedData>
          </PubmedArticle>
        XML
        expect(described_class.new(source_data).pub_hash[:date]).to eq '1999-02' # no day
      end
      # rubocop:enable RSpec/ExampleLength

      it 'sets the date to nil when not found' do
        # manual test data
        source_data = '<PubmedArticle><MedlineCitation Status="Publisher" Owner="NLM"><PMID Version="1">1</PMID><OriginalData/></PubmedArticle>'
        expect(described_class.new(source_data).pub_hash[:date]).to be_nil # no date
      end

      it 'ignores the day when not found' do
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
        expect(described_class.new(source_data).pub_hash[:date]).to eq '2017-05' # no day in one of the acceptable date paths, it zero pads the month
      end

      it 'handles a month as an abbreviation' do
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
        expect(described_class.new(source_data).pub_hash[:date]).to eq '2017-03-05' # convert Mar to 03 and zero pads the day
      end
    end

    context 'DOI extraction' do
      let(:record) { PubmedSourceRecord.send(:get_pubmed_record_from_pubmed, pmid) }
      let(:pub_hash) { described_class.new(record.source_data).pub_hash }
      let(:doi) { pub_hash[:identifier].find { |id| id[:type] == 'doi' } }

      context 'when ELocationID is missing and a URL exists' do
        let(:pmid) { 12_529_422 }

        it 'extacts the URL' do
          expect(doi).to include(url: 'https://doi.org/10.1091/mbc.e02-06-0327')
        end

        it 'extracts the id' do
          expect(doi).to include(id: '10.1091/mbc.e02-06-0327')
        end
      end

      context 'when ArticleId is present' do
        context 'works when ELocationID is present' do
          let(:pmid) { 23_453_302 }

          it 'extracts the id' do
            expect(doi).to include(id: '10.1016/j.neunet.2013.01.016')
          end
        end

        context 'when record is longer than 64kb' do
          let(:pmid) { 26_430_984 }

          it 'extracts the id' do
            expect(doi).to include(id: '10.1103/PhysRevLett.115.121604')
          end
        end
      end

      context 'when ArticleId is missing' do
        let(:pmid) { 26_858_277 }

        it 'extracts the id from ELocationID' do
          expect(doi).to include(id: '10.1136/bmj.i493')
        end
      end
    end
  end
end
