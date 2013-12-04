require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PubmedHarvester do

  let(:author) {FactoryGirl.create :author }

  let(:pub_hash) {{title: "some title",
                   year: 1938,
                   issn: '32242424',
                   pages: '34-56',
                   author: [{name: "jackson joe"}],
                   authorship: [{sul_author_id: author.id, status: "denied", visibility: "public", featured: true} ],
                   identifier: [{:type => "x", :id => "y", :url => "z"}]
                }}

  let(:publication) {
    p = FactoryGirl.create :pub_with_sw_id_and_pmid
    p.pub_hash = pub_hash
    p.save
    p
  }

  before(:each) do
    publication
  end

  describe ".search_all_sources_by_pmid" do

    it "searches for a local Publication by pmid and returns a pubhash" do
      h = PubmedHarvester.search_all_sources_by_pmid 10048354
      expect(h.first[:issn]).to eq '32242424'
    end

    it "searches ScienceWire by pmid when not found locally and returns a pubhash" do
      VCR.use_cassette('pubmed_harvester_spec_find_by_pmid_through_sw') do
        h = PubmedHarvester.search_all_sources_by_pmid 10487815
        expect(h.first[:sw_id]).to eq '10340243'
        expect(h.first[:chicago_citation]).to match(/Convergence and Correlations/)
      end
    end

    it "searches Pubmed by pmid if not found in ScienceWire and returns a pubhash" do
      VCR.use_cassette('pubmed_harvester_spec_find_by_pmid_through_pubmed') do
        h = PubmedHarvester.search_all_sources_by_pmid 24196758
        expect(h.first[:provenance]).to eq('pubmed')
        expect(h.first[:identifier]).to include( {:type=>"doi", :id=>"10.1590/S0325-00752013000600003", :url=>"http://dx.doi.org/10.1590/S0325-00752013000600003"} )
        expect(h.first[:chicago_citation]).to match(/Rights and Responsibilities of Electronic Health Records/)
      end
    end

    context "mix of local plus SW/pubmed results" do

      it "filters out batch/manual pubs from the resultset if SW/pubmed records were found" do
        VCR.use_cassette('pubmed_harvester_spec_filter_batch_manual') do
          pub2 = Publication.new
          pub2.pub_hash = pub_hash
          pub2.pub_hash[:provanance] = 'batch'
          pub2.pmid = 10487815
          pub2.save

          h = PubmedHarvester.search_all_sources_by_pmid 10487815
          expect(h.size).to eq 1
          expect(h.first[:sw_id]).to eq '10340243'
        end
      end

      it "does not do any filtering with a resultset of 2 manual/batch pubs" do
        VCR.use_cassette('pubmed_harvester_spec_no_filtering_local_only') do
          ph = pub_hash.clone
          ph[:provanance] = 'cap'
          publication.pmid = 99999999  # Pubmed ID that does not exist
          publication.pub_hash = ph
          publication.save

          pub2 = Publication.new
          pub2.pub_hash = pub_hash
          pub2.pub_hash[:title] = 'batch pub'
          pub2.pub_hash[:provanance] = 'batch'
          pub2.pmid = 99999999
          pub2.save

          h = PubmedHarvester.search_all_sources_by_pmid 99999999
          expect(h.size).to eq 2
          expect(h.map {|hash| hash[:title]}).to include('batch pub', 'some title')
        end
      end

    end

  end
end
