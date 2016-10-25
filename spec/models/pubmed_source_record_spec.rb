require 'spec_helper'
SingleCov.covered!

describe PubmedSourceRecord, :vcr do
  let(:pmid_created_1999) { 10_000_166 }

  def author_doc(xml)
    Nokogiri::XML(xml).at_xpath('/Author')
  end

  describe 'parses valid <Author> examples' do
    ##
    # Example <Author> records from No. 20 at
    # https://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
    let(:author_valid) do
      {
        Abrams: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Abrams</LastName> <ForeName>Judith</ForeName> <Initials>J</Initials> </Author>'),
          hash: {firstname: 'Judith', middlename: nil, lastname: 'Abrams'}
        },
        Amara: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Amara</LastName> <ForeName>Mohamed el-Walid</ForeName> <Initials>Mel- W</Initials> </Author>'),
          hash: {firstname: 'Mohamed', middlename: 'el-Walid', lastname: 'Amara'}
        },
        Buncke: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Buncke</LastName> <ForeName>Gregory M</ForeName> <Initials>GM</Initials> </Author>'),
          hash: {firstname: 'Gregory', middlename: 'M', lastname: 'Buncke'}
        },
        Gonzales: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Gonzales-loza</LastName> <ForeName>María del R</ForeName> <Initials>Mdel R</Initials> </Author>'),
          hash: {firstname: 'María', middlename: 'del R', lastname: 'Gonzales-loza'}
        },
        Johnson: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Johnson</LastName> <Initials>DL</Initials> </Author>'),
          hash: {firstname: 'D', middlename: 'L', lastname: 'Johnson'}
        },
        Krylov: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Krylov</LastName> <ForeName>Iakobish K</ForeName> <Initials>IaK</Initials> </Author>'),
          hash: {firstname: 'Iakobish', middlename: 'K', lastname: 'Krylov'}
        },
        Melosh: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Melosh</LastName> <ForeName>H J</ForeName> <Suffix>3rd</Suffix> <Initials>HJ</Initials> </Author>'),
          hash: {firstname: 'H', middlename: 'J', lastname: 'Melosh'}
        },
        Todoroki: {
          xml: author_doc(' <Author ValidYN="Y"> <LastName>Todoroki</LastName> <ForeName>Shin-ichi</ForeName> <Initials>S</Initials> </Author>'),
          hash: {firstname: 'Shin-ichi', middlename: nil, lastname: 'Todoroki'}
        }
      }
    end

    def check_author_hash(author)
      author_xml = author_valid[author][:xml]
      author_hash = subject.send(:author_to_hash, author_xml)
      expect(author_hash).to eq author_valid[author][:hash]
    end
    it 'extracts names for Amara example' do
      check_author_hash(:Amara)
    end
    it 'extracts names for Abrams example' do
      check_author_hash(:Abrams)
    end
    it 'extracts names for Buncke example' do
      check_author_hash(:Buncke)
    end
    it 'extracts names for Gonzales example' do
      check_author_hash(:Gonzales)
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
  end

  describe 'parses invalid <Author> examples' do
    let(:author_invalid) do
      {
        # When an author name is corrected, it is still in the AuthorList, but
        # it is flagged with `ValidYN="N"`.
        Whitely: {
          xml: author_doc(' <Author ValidYN="N"> <LastName>Whitely</LastName> <ForeName>R J</ForeName> <Initials>RJ</Initials> </Author>'),
          hash: nil
        },
        Whitely_Malformed: { # missing ValidYN attribute
          xml: author_doc(' <Author> <LastName>Whitely</LastName> <ForeName>R J</ForeName> <Initials>RJ</Initials> </Author>'),
          hash: nil
        },
        Collective: {
          xml: author_doc(' <Author ValidYN="Y"> <CollectiveName>SBU-group. Swedish Council of Technology Assessment in Health Care</CollectiveName> </Author>'),
          hash: nil
        }
      }
    end

    def check_author_hash(author)
      author_xml = author_invalid[author][:xml]
      author_hash = subject.send(:author_to_hash, author_xml)
      expect(author_hash).to eq author_invalid[author][:hash]
    end
    it 'extracts nothing for Whitely example' do
      check_author_hash(:Whitely)
    end
    it 'extracts nothing for malformed Whitely example' do
      check_author_hash(:Whitely_Malformed)
    end
    it 'extracts nothing for Collective example' do
      check_author_hash(:Collective)
    end
  end

  describe '.get_pubmed_record_from_pubmed' do
    it 'returns an instance of PubmedSourceRecord' do
      record = described_class.get_pubmed_record_from_pubmed(pmid_created_1999)
      expect(record).to be_an described_class
    end
    it 'calls PubmedSourceRecord.get_and_store_records_from_pubmed' do
      expect(described_class).to receive(:get_and_store_records_from_pubmed)
      described_class.get_pubmed_record_from_pubmed(pmid_created_1999)
    end
    it 'extracts fields - pmid' do
      record = described_class.get_pubmed_record_from_pubmed(pmid_created_1999)
      expect(record.pmid).to eq pmid_created_1999
    end
  end

  context '.source_as_hash' do
    context 'DOI extraction' do
      def doi(pmid)
        record = described_class.get_pubmed_record_from_pubmed(pmid)
        return nil if record.nil?
        record.source_as_hash[:identifier].find { |id| id[:type] == 'doi' }
      end
      it 'constructs a URL based on the DOI' do
        expect(doi(12_529_422)).to include(url: 'https://dx.doi.org/10.1091/mbc.E02-06-0327')
      end
      context 'extracts from ArticleId' do
        it 'works when ELocationID is missing' do
          expect(doi(12_529_422)).to include(id: '10.1091/mbc.E02-06-0327')
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
