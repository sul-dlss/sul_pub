require 'spec_helper'

describe BibtexIngester do
	let!(:author_with_bibtex) { create :author, sunetid: "james", cap_profile_id: 333333 }
	let!(:bibtex_ingester) {BibtexIngester.new}

	#	puts author_with_bibtex.to_s

	describe "#harvest_from_directory_of_bibtex_files" do

	  it "creates pub for each new bibtex record" do
        expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to change(Publication, :count).by(4)
		expect(author_with_bibtex.publications).to have(4).items
	  end

	  it "associates pubs with author by sunet" do
        	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
			expect(author_with_bibtex.publications).to have(4).items
	  end

	  it "doesn't duplicate existing publications" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to_not change(Publication, :count)

	  end
	  it "doesn't duplicate existing publication identifiers" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)

		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to_not change(PublicationIdentifier, :count)

	  end
	  it "doesn't duplicate existing contributions" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)

		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to_not change(Contribution, :count)
	  end
	  it "creates new publication identifiers" do

	  	expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to change(PublicationIdentifier, :count).by(2)
	  end
	  it "creates new contributions" do

	  	expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to change(Contribution, :count).by(4)
	  end

	  it "creates BatchUploadedSourceRecord" do
	  	expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to change(BatchUploadedSourceRecord, :count).by(4)
	  end

	  it "adds citations to pub_hash" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	pub = Publication.last
	  	expect(pub.pub_hash[:chicago_citation]).to include(pub.year)
	  	expect(pub.pub_hash[:apa_citation]).to include(pub.year)
	  	expect(pub.pub_hash[:mla_citation]).to include(pub.year)
	  	expect(pub.pub_hash[:chicago_citation].downcase).to include(pub.title.downcase)
	  	expect(pub.pub_hash[:apa_citation].downcase).to include(pub.title.downcase)
	  	expect(pub.pub_hash[:mla_citation].downcase).to include(pub.title.downcase)
	  end


	  it "puts issn into journal part of pubhash" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	pub = Publication.where(title: 'Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly').first

	  	expect(pub.pub_hash[:journal][:identifier].select {|k| k[:type] == 'issn'}.first[:id]).to include('5555')

	  end


	  it "adds publication_identifier for isbn" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	expect(PublicationIdentifier.exists?(identifier_type: 'isbn', identifier_value: 3233333)).to be_true
	  end

	  it "adds publication_identifier for DOI" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	expect(PublicationIdentifier.exists?(identifier_type: 'doi', identifier_value: 8484848484)).to be_true
	  end

	  it "doesn't add publication_identifier for sulpubid" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	pub = Publication.where(title: 'Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly').first

	  	expect(PublicationIdentifier.exists?(identifier_type: 'SULPubId', identifier_value: pub.id)).to be_false
	  end

	  it "puts SULPubId into identifer part of pubhash" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	pub = Publication.where(title: 'Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly').first
	  	expect(pub.pub_hash[:identifier].select {|k| k[:type] == 'SULPubId'}.first[:id]).to match(pub.id.to_s)
	  end

    it "puts DOI into identifer part of pubhash" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	pub = Publication.where(title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living').first
	  	expect(pub.pub_hash[:identifier].select {|k| k[:type] == 'doi'}.first[:id]).to match('8484848484')
	  end

    it "puts isbn into identifer part of pubhash" do
	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	pub = Publication.where(title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living').first
	  	expect(pub.pub_hash[:identifier].select {|k| k[:type] == 'isbn'}.first[:id]).to match('3233333')
	  end

	  it "places all of the authors into the allAuthors field of the pub_hash" do
	    bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
	  	pub = Publication.where(title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living').first
	  	expect(pub.pub_hash[:allAuthors]).to eq 'Goldstein, Mary Kane, Miller, David E., Davies, Sheryl M., Garber, Alan M.'
	  end


	  context "when depuping by issn, year, pages" do
	  	let!(:existing_matching_pub_issn) {create :publication, pmid: 3323434, pub_hash: {title: 'Quelque Titre', type: 'article', pmid: 3323434, year: 2002, pages: '295-299', issn: '234234', author: [{name: "Jackson, Joe"}], authorship:[{sul_author_id: 2222, status: "denied", visibility: "public", featured: true}]}}
	  	let!(:contribution) {create :contribution, author: author_with_bibtex, publication: existing_matching_pub_issn}


		it "doesn't add duplicate contributions" do
			#puts existing_matching_pub_issn.to_yaml
	  		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to change(Contribution, :count).by(3)
		end
		it "doesn't add duplicate publication identifiers" do
	  		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to change(PublicationIdentifier, :count).by(0)
	  end

	  it "doesn't duplicate existing publications" do
	  		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
						}.to change(Publication, :count).by(3)
		end
	end

  	context "when depuping by title, year, pages" do
  	  let!(:pub_with_same_title) {create :publication, pmid: 332423434, pub_hash: {title: 'Quality of Life Assessment Designed for Computer Inexperienced Older Adults: Multimedia Utility Elicitation for Activities of Daily Living', pmid: 3323434, type: 'article', year: 2002, pages: '295-299', author: [{name: "Jackson, Joe"}], authorship:[{sul_author_id: 2222, status: "denied", visibility: "public", featured: true}]}}
  	  let!(:contribution) {create :contribution, author: author_with_bibtex, publication: pub_with_same_title}

  		it "doesn't add duplicate contributions" do
  			#puts pub_with_title.to_yaml
  	  		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  						}.to change(Contribution, :count).by(3)
  		end

  		it "doesn't add duplicate publication identifiers" do
  	  		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  						}.to change(PublicationIdentifier, :count).by(0)
  	  end

  	  it "doesn't duplicate existing publications" do
  	  		expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  						}.to change(Publication, :count).by(3)
  		end
  	end

  	context "when reimporting with change" do

  		 # it "updates old record with new title" do
  		 # 	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  		 # 	oldPub = Publication.where(title: "Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly ").first
  		 # 	expect {
  	  	 #		bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch_2').to_s)
  		 #	}.to change { oldPub.pub_hash[:title] }.from("Systematic Review: The Safety and Efficacy of Growth Hormone in the Healthy Elderly ").
  		#		to("The new title")
  		 # end

  	   it "doesn't duplicate identifiers" do
  		  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  		  	expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  						}.to_not change(PublicationIdentifier, :count)
  		 end

  		it "doesn't duplicate publications" do
  		  bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  		  expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  						}.to_not change(Publication, :count)
  		end

  		it "doesn't duplicate contributions" do
  		  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  		  	expect {bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  						}.to_not change(Contribution, :count)
  		end

  		it "updates changed issn" do
  	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch').to_s)
  	  	oldPub = Publication.where(issn: "234234").first
  	  #	puts "issn:  #{oldPub.pub_hash[:issn]}"
  	  	expect(oldPub.pub_hash[:issn]).to match('234234')
  	  	bibtex_ingester.ingest_from_source_directory(Rails.root.join('fixtures', 'bibtex_for_batch_2').to_s)
  	  	oldPub.reload
  	  	expect(oldPub.pub_hash[:issn]).to match("234235")
  	  	#oldPub = Publication.first
  	  #	puts "old pub: #{oldPub.to_yaml}"

  		end

  	end

  end
end