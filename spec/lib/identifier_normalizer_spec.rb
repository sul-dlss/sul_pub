describe IdentifierNormalizer do
  subject(:normalizer) { described_class.new }

  let(:doi_identifier) { create(:doi_pub_id) }
  let(:doi_pub) { doi_identifier.publication }
  let(:null_logger) { Logger.new('/dev/null') }

  before { allow(Logger).to receive(:new).and_return(null_logger) }

  shared_examples 'preserves_value' do
    it 'does not change PublicationIdentifier.identifier_value' do
      expect { normalizer.normalize_record(doi_identifier) }.not_to change {
        doi_identifier.reload.identifier_value
      }
    end
  end

  shared_examples 'preserves_uri' do
    it 'does not change PublicationIdentifier.identifier_uri' do
      expect { normalizer.normalize_record(doi_identifier) }.not_to change {
        doi_identifier.reload.identifier_uri
      }
    end
  end

  shared_examples 'preserves_pub_hash' do
    it 'updates Publication.pub_hash' do
      expect { normalizer.normalize_record(doi_identifier) }.not_to change {
        doi_pub.reload.pub_hash[:identifier]
      }
    end
  end

  shared_examples 'updates_value' do
    it 'updates PublicationIdentifier.identifier_value' do
      expect { normalizer.normalize_record(doi_identifier) }.to change {
        doi_identifier.reload.identifier_value
      }
    end
  end

  shared_examples 'updates_uri' do
    it 'updates PublicationIdentifier.identifier_uri' do
      expect { normalizer.normalize_record(doi_identifier) }.to change {
        doi_identifier.reload.identifier_uri
      }
    end
  end

  shared_examples 'updates_pub_hash' do
    it 'updates Publication.pub_hash' do
      expect { normalizer.normalize_record(doi_identifier) }.to change {
        doi_pub.reload.pub_hash[:identifier]
      }
    end
  end

  shared_examples 'deletes_pub_id' do
    it 'decreases PublicationIdentifier.count' do
      expect { normalizer.normalize_record(doi_identifier) }.to change {
        PublicationIdentifier.count
      }
    end
  end

  shared_examples 'deletes_pub_hash_entry' do
    it_behaves_like 'updates_pub_hash'
    it 'updates Publication.pub_hash' do
      normalizer.normalize_record(doi_identifier)
      ids = doi_pub.reload.pub_hash[:identifier]
      id = ids.find { |i| i[:type] == 'doi' }
      expect(id).to be_nil
    end
  end

  describe '#new' do
    it { is_expected.not_to be_nil }
  end

  describe '#normalize_record' do
    it 'works' do
      result = normalizer.normalize_record(doi_identifier)
      expect(result).to be_nil
    end

    context 'error' do
      it 'logs ArgumentError' do
        expect(null_logger).to receive(:error)
        normalizer.normalize_record('a pub_id')
      end
    end
  end

  describe '#normalize_record with valid data' do
    # normalizer preserves valid data, even with save_changes == true
    before { normalizer.save_changes = true }
    it_behaves_like 'preserves_value'
    it_behaves_like 'preserves_uri'
    it_behaves_like 'preserves_pub_hash'
  end

  describe '#normalize_record with empty data' do
    # normalizer can delete blank data
    let(:doi_identifier) { create(:doi_pub_id, identifier_value: nil) }
    before do
      normalizer.delete_blanks = true
      doi_identifier.save
    end

    it_behaves_like 'deletes_pub_id'
    it_behaves_like 'deletes_pub_hash_entry'
  end

  describe '#normalize_record with partial valid data' do
    before { normalizer.save_changes = true }

    context 'valid value, empty URI' do
      let(:doi_identifier) { create(:doi_pub_id, identifier_uri: nil) }

      it_behaves_like 'preserves_value'
      it_behaves_like 'updates_uri'
      it_behaves_like 'updates_pub_hash'
    end

    context 'valid URI, empty value' do
      let(:doi_identifier) { create(:doi_pub_id, identifier_value: nil, identifier_uri: 'http://dx.doi.org/10.1038/ncomms3199') }

      it_behaves_like 'updates_value'
      it_behaves_like 'preserves_uri'
      it_behaves_like 'updates_pub_hash'
    end
  end

  describe '#normalize_record with denormalized valid data' do
    before { normalizer.save_changes = true }

    context 'valid denormalized value, empty URI' do
      # Altmetrics identifiers gem normalizes this value to:
      # > Identifiers::DOI.extract 'http://dx.doi.org/10.1038/ncomms3199'
      # => ["10.1038/ncomms3199"]
      let(:doi_identifier) { create(:doi_pub_id, identifier_uri: nil, identifier_value: 'http://dx.doi.org/10.1038/ncomms3199') }

      it_behaves_like 'updates_value'
      it_behaves_like 'updates_uri'
      it_behaves_like 'updates_pub_hash'
    end
  end

  describe '#normalize_record with invalid data' do
    # Invalid according to: Identifiers::DOI.extract '10.1038/'
    let(:doi_identifier) { create(:doi_pub_id, identifier_value: '10.1038/') }

    # normalizer can delete invalid data
    before do
      normalizer.delete_invalid = true
      doi_identifier.save
    end

    it_behaves_like 'deletes_pub_id'
    it_behaves_like 'deletes_pub_hash_entry'
  end

  # ---
  # PRIVATE METHODS

  describe '#identifier_parser' do
    it 'works for doi' do
      result = normalizer.send(:identifier_parser, doi_identifier)
      expect(result).to be_an IdentifierParserDOI
    end
    it 'works for isbn' do
      result = normalizer.send(:identifier_parser, create(:isbn_publication_identifier))
      expect(result).to be_an IdentifierParserISBN
    end
    it 'works for pmid' do
      result = normalizer.send(:identifier_parser, create(:pmid_publication_identifier))
      expect(result).to be_an IdentifierParserPMID
    end
    it 'works for SulPubId' do
      result = normalizer.send(:identifier_parser, create(:sul_publication_identifier))
      expect(result).to be_an IdentifierParser
    end
    it 'works for PublicationItemID' do
      result = normalizer.send(:identifier_parser, create(:publicationItemID_publication_identifier))
      expect(result).to be_an IdentifierParser
    end
  end
end
