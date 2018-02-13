
describe BibtexIngester do
  subject(:bibtex_ingester) { described_class.new }

  let!(:author_with_bibtex) { create :author, sunetid: 'james', cap_profile_id: 333_333 }

  let(:bibtex_batch_path) { Rails.root.join('spec', 'fixtures', 'bibtex', 'batch1').to_s }
  let(:bibtex_batch_path2) { Rails.root.join('spec', 'fixtures', 'bibtex', 'batch2').to_s }

  #	puts author_with_bibtex.to_s

  describe '#harvest_from_directory_of_bibtex_files' do
    it 'creates pub for each new bibtex record' do
      expect do
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      end.to change(Publication, :count).by(4)
      expect(author_with_bibtex.publications.size).to eq(4)
    end

    it 'associates pubs with author by sunet' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      expect(author_with_bibtex.publications.size).to eq(4)
    end

    it "doesn't duplicate existing publications" do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      expect do
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      end.not_to change(Publication, :count)
    end

    it "doesn't duplicate existing publication identifiers" do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      expect do
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      end.not_to change(PublicationIdentifier, :count)
    end

    it "doesn't duplicate existing contributions" do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      expect do
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      end.not_to change(Contribution, :count)
    end

    it 'creates new publication identifiers' do
      expect do
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      end.to change(PublicationIdentifier, :count).by(4)
    end

    it 'creates new contributions' do
      expect do
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      end.to change(Contribution, :count).by(4)
    end

    it 'creates BatchUploadedSourceRecord' do
      expect do
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      end.to change(BatchUploadedSourceRecord, :count).by(4)
    end

    it 'adds citations to pub_hash' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      pub = Publication.last
      expect(pub.pub_hash[:chicago_citation]).to include(pub.year)
      expect(pub.pub_hash[:apa_citation]).to include(pub.year)
      expect(pub.pub_hash[:mla_citation]).to include(pub.year)
      expect(pub.pub_hash[:chicago_citation].downcase).to include(pub.title.downcase)
      expect(pub.pub_hash[:apa_citation].downcase).to include(pub.title.downcase)
      expect(pub.pub_hash[:mla_citation].downcase).to include(pub.title.downcase)
    end

    it 'puts issn into journal part of pubhash' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      pub = Publication.where(title: 'Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly').first
      expect(pub.pub_hash[:journal][:identifier].find { |k| k[:type] == 'issn' }[:id]).to include('5555')
    end

    it 'adds publication_identifier for isbn' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      expect(PublicationIdentifier.exists?(identifier_type: 'isbn', identifier_value: 3_233_333)).to be_truthy
    end

    it 'adds publication_identifier for DOI' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      expect(PublicationIdentifier.exists?(identifier_type: 'doi', identifier_value: 8_484_848_484)).to be_truthy
    end

    it "doesn't add publication_identifier for sulpubid" do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      pub = Publication.where(title: 'Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly').first
      expect(PublicationIdentifier.exists?(identifier_type: 'SULPubId', identifier_value: pub.id)).to be_falsey
    end

    it 'puts SULPubId into identifer part of pubhash' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      pub = Publication.where(title: 'Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly').first
      expect(pub.pub_hash[:identifier].find { |k| k[:type] == 'SULPubId' }[:id]).to match(pub.id.to_s)
    end

    it 'puts DOI into identifer part of pubhash' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      pub = Publication.where(title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living').first
      expect(pub.pub_hash[:identifier].find { |k| k[:type] == 'doi' }[:id]).to match('8484848484')
    end

    it 'puts isbn into identifer part of pubhash' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      pub = Publication.where(title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living').first
      expect(pub.pub_hash[:identifier].find { |k| k[:type] == 'isbn' }[:id]).to match('3233333')
    end

    it 'places all of the authors into the allAuthors field of the pub_hash' do
      bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      pub = Publication.where(title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living').first
      expect(pub.pub_hash[:allAuthors]).to eq 'Goldstein, Mary Kane, Miller, David E., Davies, Sheryl M., Garber, Alan M.'
    end

    context 'when deduping by issn, year, pages' do
      let(:issn) { '234234' }
      let(:pmid) { 3_323_434 }
      let(:existing_matching_pub_issn) do
        pub = create(:publication,
                     pmid: pmid,
                     issn: issn,
                     pub_hash: {
                       title: 'Quelque Titre',
                       type: 'article',
                       pmid: pmid,
                       year: 2002,
                       pages: '295-299',
                       issn: issn,
                       author: [{ name: 'Jackson, Joe' }],
                       authorship: [{ sul_author_id: 2222, status: 'denied', visibility: 'public', featured: true }],
                       identifier: [{ type: 'issn', id: issn }, { type: 'pmid', id: pmid }]
                     })
        pub.sync_publication_hash_and_db
        pub
      end
      let(:contribution) { create :contribution, author: author_with_bibtex, publication: existing_matching_pub_issn }

      before do
        contribution # exists
      end

      it "doesn't add duplicate contributions" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.to change(Contribution, :count).by(3)
      end

      it "doesn't add duplicate publication identifiers" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.to change(PublicationIdentifier, :count).by(0)
      end

      it "doesn't duplicate existing publications" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.to change(Publication, :count).by(3)
      end
    end

    context 'when deduping by title, year, pages' do
      let(:pmid) { 3_323_434 }
      let!(:pub_with_same_title) do
        pub = create(:publication,
                     pmid: pmid,
                     pub_hash: {
                       title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living',
                       pmid: pmid,
                       type: 'article',
                       year: 2002,
                       pages: '295-299',
                       author: [{ name: 'Jackson, Joe' }],
                       authorship: [{ sul_author_id: 2222, status: 'denied', visibility: 'public', featured: true }],
                       identifier: [{ type: 'pmid', id: pmid }]
                     })
        pub.sync_publication_hash_and_db
        pub
      end
      let(:contribution) { create :contribution, author: author_with_bibtex, publication: pub_with_same_title }

      before do
        contribution # exists
      end

      it "doesn't add duplicate contributions" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.to change(Contribution, :count).by(3)
      end

      it "doesn't add duplicate publication identifiers" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.to change(PublicationIdentifier, :count).by(0)
      end

      it "doesn't duplicate existing publications" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.to change(Publication, :count).by(3)
      end
    end

    context 'when reimporting with change' do
      # it "updates old record with new title" do
      # 	bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
      # 	oldPub = Publication.where(title: "Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly ").first
      # 	expect {
      #		bibtex_ingester.ingest_from_source_directory(bibtex_batch_path2)
      #	}.to change { oldPub.pub_hash[:title] }.from("Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly ").
      #		to("The new title")
      # end

      before { bibtex_ingester.ingest_from_source_directory(bibtex_batch_path) }

      it "doesn't duplicate identifiers" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.not_to change(PublicationIdentifier, :count)
      end

      it "doesn't duplicate publications" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.not_to change(Publication, :count)
      end

      it "doesn't duplicate contributions" do
        expect do
          bibtex_ingester.ingest_from_source_directory(bibtex_batch_path)
        end.not_to change(Contribution, :count)
      end

      it 'updates changed issn' do
        old_pub = Publication.where(issn: '234234').first
        #	puts "issn:  #{oldPub.pub_hash[:issn]}"
        expect(old_pub.pub_hash[:issn]).to match('234234')
        bibtex_ingester.ingest_from_source_directory(bibtex_batch_path2)
        old_pub.reload
        expect(old_pub.pub_hash[:issn]).to match('234235')
        # oldPub = Publication.first
        #	puts "old pub: #{oldPub.to_yaml}"
      end
    end
  end
end
