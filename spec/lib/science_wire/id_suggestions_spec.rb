SingleCov.covered!

describe ScienceWire::IdSuggestions do
  let(:author_attributes) { double 'author_attributes' }
  let(:client) { double 'client' }
  subject { described_class.new(client: client) }
  describe '#id_suggestions' do
    it 'combines journal_suggestions and conference_suggestions' do
      expect(subject).to receive(:journal_suggestions).and_return [0]
      expect(subject).to receive(:conference_suggestions).and_return [1]
      expect(subject.id_suggestions(author_attributes)).to eq [0, 1]
    end
  end
  describe '#journal_suggestions' do
    it 'call suggestions' do
      expect(subject).to receive(:suggestions).and_return [1, 2, 3]
      expect(subject.journal_suggestions(author_attributes)).to eq [1, 2, 3]
    end
  end
  describe '#conference_suggestions' do
    it 'call suggestions' do
      expect(subject).to receive(:suggestions).and_return [1, 2, 3]
      expect(subject.conference_suggestions(author_attributes)).to eq [1, 2, 3]
    end
  end
end
