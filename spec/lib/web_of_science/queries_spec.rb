# frozen_string_literal: true

describe WebOfScience::Queries do
  subject(:wos_queries) { described_class.new }

  describe '#retrieve_by_id' do
    let(:retriever) { instance_double(WebOfScience::IdQueryRestRetriever) }

    let(:ids) { %w[WOS:A1976BW18000001 WOS:A1972N549400003] }
    let(:query) { WebOfScience::IdQueryRestRetriever::Query.new(ids:) }

    before do
      allow(WebOfScience::IdQueryRestRetriever).to receive(:new).and_return(retriever)
    end

    it 'returns a retriever' do
      expect(wos_queries.retrieve_by_id(ids)).to eq retriever
      expect(WebOfScience::IdQueryRestRetriever).to have_received(:new).with(query)
    end
  end

  describe '#user_query' do
    let(:retriever) { instance_double(WebOfScience::UserQueryRestRetriever) }

    let(:user_query) { 'TI=A research roadmap for next-generation sequencing informatics' }
    let(:query_params) { WebOfScience::UserQueryRestRetriever::Query.new(load_time_span: '8W') }

    let(:query) { WebOfScience::UserQueryRestRetriever::Query.new(user_query:) }

    before do
      allow(WebOfScience::UserQueryRestRetriever).to receive(:new).and_return(retriever)
    end

    it 'returns a retriever' do
      expect(wos_queries.user_query(user_query, query_params:)).to eq retriever
      expect(WebOfScience::UserQueryRestRetriever).to have_received(:new).with(query, query_params:)
    end
  end

  describe '#user_query_options_to_params' do
    it 'returns a Query' do
      expect(wos_queries.user_query_options_to_params({ load_time_span: '8W' })).to eq(WebOfScience::UserQueryRestRetriever::Query.new(load_time_span: '8W'))
    end
  end
end
