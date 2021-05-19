# frozen_string_literal: true

describe PubHashValidator do
  let(:valid_pub_hash) do
    {
      title: 'Twitter Makes It Worse: Political Journalists, Gendered Echo Chambers, and the Amplification of Gender Bias',
      type: 'article'
    }
  end

  let(:invalid_pub_hash) do
    {
      title: 'Twitter Makes It Worse: Political Journalists, Gendered Echo Chambers, and the Amplification of Gender Bias',
      type: 'article',
      foo: 'bar'
    }
  end

  describe '#valid?' do
    context 'when valid' do
      it 'returns true' do
        expect(described_class.valid?(valid_pub_hash)).to be(true)
      end
    end

    context 'when invalid' do
      it 'returns false' do
        expect(described_class.valid?(invalid_pub_hash)).to be(false)
      end
    end
  end

  describe '#validate' do
    context 'when valid' do
      it 'returns empty' do
        expect(described_class.validate(valid_pub_hash)).to be_empty
      end
    end

    context 'when invalid' do
      it 'returns error' do
        expect(described_class.validate(invalid_pub_hash)).to eq(['/foo with value bar is invalid for schema: /additionalProperties'])
      end
    end

    context 'when missing required field' do
      let(:invalid_pub_hash) do
        {
          title: 'Twitter Makes It Worse: Political Journalists, Gendered Echo Chambers, and the Amplification of Gender Bias',
          identifier: [
            {
              id: 'abc123'
            }
          ]
        }
      end

      it 'returns error' do
        expect(described_class.validate(invalid_pub_hash)).to eq(['Invalid with details: {"missing_keys"=>["type"]}'])
      end
    end
  end
end
