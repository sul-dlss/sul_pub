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

  end
end
