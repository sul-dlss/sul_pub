describe SMCIReport do
  before { allow(Logger).to receive(:new).and_return(null_logger) }

  let(:null_logger) { Logger.new('/dev/null') }
  let(:input_csv) { 'spec/fixtures/reports/input.csv' }
  let(:output_csv) { 'tmp/output.csv' }

  describe '#initialize' do
    it 'raises an exception with a missing input file' do
      expect { described_class.new(input_file: 'tmp/bogus.csv', output_file: output_csv) }.to raise_error(RuntimeError)
    end
    it 'raises an exception with an unspecified output file' do
      expect { described_class.new(input_file: input_csv) }.to raise_error(RuntimeError)
    end
    it 'raises an exception with a bogus date_since' do
      expect { described_class.new(input_file: input_csv, output_file: output_csv, date_since: 'bogus') }.to raise_error(ArgumentError)
    end
  end

  describe '#run' do
    let(:author) { create :russ_altman }
    let(:publication) { create :publication }
    let(:contribution) { create :contribution }
    let(:wos_retriever) { instance_double(WebOfScience::Retriever, next_batch: WebOfScience::Records.new(records: '<xml/>')) }

    before do
      allow(WebOfScience::QueryAuthor).to receive(:new).and_return(query_author)
      allow(WebOfScience.queries).to receive(:search).and_return(wos_orcid_retriever)
      allow(query_author).to receive(:author_query).and_return('the query')
      allow(wos_retriever).to receive(:'next_batch?').and_return(false)
    end

    after { File.delete(output_csv) }

    context 'when wos returns more than the max number of publications for an author' do
      let(:lotsa_uids) { Array(1..Settings.WOS.max_publications_per_author) }
      let(:query_author) { instance_double(WebOfScience::QueryAuthor, uids: lotsa_uids, 'valid?': true) }
      let(:wos_orcid_retriever) { instance_double(WebOfScience::Retriever, merged_uids: lotsa_uids) }

      it 'runs with no dates specified' do
        author.contributions << contribution
        expect(File.exist?(output_csv)).to be false
        report = described_class.new(input_file: input_csv, output_file: output_csv)
        result = report.run
        expect(WebOfScience.queries).not_to receive(:retrieve_by_id) # lots of pubs means no need to fetch them
        expect(File.exist?(output_csv)).to be true
        expect(File.open(output_csv, 'r').readlines.size).to eq 2 # the report returns a publication for altman
        expect(result).to be true
      end

      it 'runs with dates specified' do
        expect(File.exist?(output_csv)).to be false
        report = described_class.new(input_file: input_csv, output_file: output_csv, date_since: '1/1/2020', time_span: '1year')
        result = report.run
        expect(WebOfScience.queries).not_to receive(:retrieve_by_id) # lots of pubs means no need to fetch them
        expect(File.exist?(output_csv)).to be true
        expect(File.open(output_csv, 'r').readlines.size).to eq 1 # the report does not return a publication
        expect(result).to be true
      end
    end

    context 'when wos returns less than the max number of publications for an author' do
      let(:uids) { [1, 2] }
      let(:query_author) { instance_double(WebOfScience::QueryAuthor, uids: uids, 'valid?': true) }
      let(:wos_orcid_retriever) { instance_double(WebOfScience::Retriever, merged_uids: uids) }

      before do
        allow(WebOfScience.queries).to receive(:retrieve_by_id)
          .with(uids)
          .and_return(wos_retriever)
      end

      it 'runs' do
        author.contributions << contribution
        expect(File.exist?(output_csv)).to be false
        report = described_class.new(input_file: input_csv, output_file: output_csv)
        result = report.run
        expect(File.exist?(output_csv)).to be true
        expect(File.open(output_csv, 'r').readlines.size).to eq 2 # the report returns a publication for altman
        expect(result).to be true
      end
    end
  end

  describe '#output_row' do
    let(:author) { create :russ_altman }
    let(:report) { described_class.new(input_file: input_csv, output_file: output_csv) }
    let(:pub_hash) { { publisher: 'some publisher', title: 'some title', identifier: [] } }
    let(:date) { Time.now }

    it 'creates an output for a profile author' do
      result = report.send(:output_row, pub_hash, author, date)
      expect(result).to eq(['some title', '', '', '', '', '', '', 'some publisher', '', '', '', '', nil, nil, '', nil, nil, nil, author.last_name, author.first_name, author.sunetid, author.cap_profile_id, author.university_id, author.email, date, nil, nil, nil])
    end

    it 'creates an output row for a non-profile author' do
      result = report.send(:output_row, pub_hash, nil, date)
      expect(result).to eq(['some title', '', '', '', '', '', '', 'some publisher', '', '', '', '', nil, nil, '', nil, nil, nil, '', '', '', '', '', '', date, nil, nil, nil])
    end
  end
end