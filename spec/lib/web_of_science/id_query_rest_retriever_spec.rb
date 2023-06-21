# frozen_string_literal: true

describe WebOfScience::IdQueryRestRetriever, :vcr do
  let(:retriever) { described_class.new(query) }

  let(:query) { described_class::Query.new(ids: %w[WOS:000081515000015 WOS:000346594100007]) }

  it 'retrieves records' do
    expect(retriever.next_batch?).to be true
    records = retriever.next_batch
    expect(records.count).to eq 2
    expect(records.first).to be_a WebOfScience::Record
    expect(retriever.next_batch?).to be false
  end
end
