# frozen_string_literal: true

describe SmciReport do
  before { allow(Logger).to receive(:new).and_return(null_logger) }

  let(:null_logger) { Logger.new(File::NULL) }
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
      expect do
        described_class.new(input_file: input_csv, output_file: output_csv,
                            date_since: 'bogus')
      end.to raise_error(ArgumentError)
    end
  end

  describe '#run' do
    let(:author) { create(:russ_altman) }
    let(:publication) { create(:publication) }
    let(:contribution) { create(:contribution) }
    let(:wos_retriever) do
      instance_double(WebOfScience::UserQueryRestRetriever, next_batch: WebOfScience::Records.new(records: '<xml/>'))
    end

    before do
      allow(WebOfScience::QueryName).to receive(:new).and_return(query_name)
      allow(WebOfScience::QueryOrcid).to receive(:new).and_return(query_orcid)
      allow(query_name).to receive(:name_query).and_return('the query')
      allow(query_orcid).to receive(:orcid_query).and_return('the query')
      allow(wos_retriever).to receive(:next_batch?).and_return(false)
    end

    after { File.delete(output_csv) }

    context 'when wos returns more than the max number of publications for an author' do
      let(:lotsa_uids) { Array(1..Settings.WOS.max_publications_per_author) }
      let(:query_name) { instance_double(WebOfScience::QueryName, uids: lotsa_uids, valid?: true) }
      let(:query_orcid) { instance_double(WebOfScience::QueryOrcid, uids: [], valid?: true) }

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
        report = described_class.new(input_file: input_csv, output_file: output_csv, date_since: '1/1/2020',
                                     time_span: '1year')
        result = report.run
        expect(WebOfScience.queries).not_to receive(:retrieve_by_id) # lots of pubs means no need to fetch them
        expect(File.exist?(output_csv)).to be true
        expect(File.open(output_csv, 'r').readlines.size).to eq 1 # the report does not return a publication
        expect(result).to be true
      end
    end

    context 'when wos returns less than the max number of publications for an author with an orcid' do
      let(:uids) { [1, 2] }
      let(:orcid_uids) { [2, 3] }
      let(:query_name) { instance_double(WebOfScience::QueryName, uids:, valid?: true) }
      let(:query_orcid) { instance_double(WebOfScience::QueryOrcid, uids: orcid_uids, valid?: true) }

      before do
        allow(WebOfScience.queries).to receive(:retrieve_by_id)
          .with(uids)
          .and_return(wos_retriever)
        allow(WebOfScience.queries).to receive(:retrieve_by_id)
          .with(orcid_uids)
          .and_return(wos_retriever)
      end

      it 'runs' do
        expect(WebOfScience.queries).to receive(:retrieve_by_id).with(uids)
        expect(WebOfScience.queries).to receive(:retrieve_by_id).with(orcid_uids)
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
    let(:author) { create(:russ_altman) }
    let(:report) { described_class.new(input_file: input_csv, output_file: output_csv) }
    let(:pub_hash) { { publisher: 'some publisher', title: 'some title', identifier: [] } }
    let(:date) { Time.zone.now }

    it 'creates an output for a profile author' do
      result = report.send(:output_row, pub_hash:, author:, harvested_at: date,
                                        publication_status: 'new')
      expect(result).to eq(['some title', '', '', '', '', '', '', 'some publisher', '', '', '', '', nil, nil, '', nil,
                            nil, nil, nil, author.last_name, author.first_name, author.sunetid, author.cap_profile_id,
                            author.university_id, author.email, 'new', date, nil, nil, nil])
    end

    it 'creates an output row for a non-profile author' do
      result = report.send(:output_row, orcid: '1234', pub_hash:)
      expect(result).to eq(['some title', '', '', '', '', '', '', 'some publisher', '', '', '', '', nil, nil, '', nil,
                            nil, nil, '1234', '', '', '', '', '', '', 'unknown', Time.now.utc.to_fs(:db), nil, nil, nil])
    end
  end
end
