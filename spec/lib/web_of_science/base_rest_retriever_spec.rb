# frozen_string_literal: true

describe WebOfScience::BaseRestRetriever, :vcr do
  let(:retriever) { described_class.new('/', params) }

  let(:params) do
    {
      usrQuery: 'AI=("0000-0003-3859-2905")'
    }
  end

  it 'retrieves records' do
    expect(retriever.next_batch?).to be true
    records = retriever.next_batch
    expect(records.count).to eq 100
    expect(records.first).to be_a WebOfScience::Record
    expect(retriever.next_batch?).to be true
    records = retriever.next_batch
    expect(records.count).to eq 89 # this number can increase if you create new cassettes if the user has more publications
    expect(retriever.next_batch?).to be false
  end
end
