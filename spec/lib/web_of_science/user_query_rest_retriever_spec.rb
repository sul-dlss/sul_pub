# frozen_string_literal: true

describe WebOfScience::UserQueryRestRetriever, :vcr do
  let(:retriever) { described_class.new(query, query_params:) }

  let(:query) { described_class::Query.new(user_query: 'AI=("0000-0003-3859-2905")') }

  let(:query_params) { nil }

  it 'retrieves records' do
    expect(retriever.next_batch?).to be true
    records = retriever.next_batch
    expect(records.count).to eq 100
    expect(records.first).to be_a WebOfScience::Record
    expect(retriever.next_batch?).to be true
    records = retriever.next_batch
    expect(records.count).to eq 56
    expect(retriever.next_batch?).to be false
  end

  context 'with a loadTimeSpan' do
    let(:query) { described_class::Query.new(user_query: 'AI=("0000-0003-3859-2905")', load_time_span: '1Y') }

    let(:query_params) { described_class::Query.new(user_query: 'AI=("0000-0003-3859-2905")', load_time_span: '1Y') }

    it 'retrieves records' do
      expect(retriever.next_batch?).to be true
      records = retriever.next_batch
      expect(records.count).to eq 6
    end
  end

  context 'with a loadTimeSpan as a query param' do
    let(:query) { described_class::Query.new(user_query: 'AI=("0000-0003-3859-2905")') }

    let(:query_params) { described_class::Query.new(load_time_span: '1Y') }

    it 'retrieves records' do
      expect(retriever.next_batch?).to be true
      records = retriever.next_batch
      expect(records.count).to eq 6
    end
  end
end
