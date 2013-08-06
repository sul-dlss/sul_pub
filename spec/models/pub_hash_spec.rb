require 'spec_helper'

describe PubHash do
	let(:pub_hash) {
	  {:provenance=>"sciencewire",
     :pmid=>"15572175",
     :sw_id=>"6787731",
     :title=>
      "New insights into the expression and function of neural connexins with transgenic mouse mutants",
     :abstract_restricted=>
      "Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv",
     :author=>
      [{:name=>"Sohl,G,"},
       {:name=>"Odermatt,B,"},
       {:name=>"Maxeiner,S,"},
       {:name=>"Degen,J,"},
       {:name=>"Willecke,K,"},
       {:name=>"Last,O"}],
     :year=>"2004",
     :date=>"2004-12-01T00:00:00",
     :authorcount=>"6",
     :documenttypes_sw=>["Article"],
     :type=>"article",
     :documentcategory_sw=>"Conference Proceeding Document",
     :publicationimpactfactorlist_sw=>
      ["4.617,2004,ExactPublicationYear", "10.342,2011,MostRecentYear"],
     :publicationcategoryrankinglist_sw=>
      ["28/198;NEUROSCIENCES;2004;SC;ExactPublicationYear",
       "10/242;NEUROSCIENCES;2011;SC;MostRecentYear"],
     :numberofreferences_sw=>"159",
     :timescited_sw_retricted=>"40",
     :timenotselfcited_sw=>"30",
     :authorcitationcountlist_sw=>"1,2,38|2,0,40|3,3,37|4,0,40|5,10,30",
     :rank_sw=>"",
     :ordinalrank_sw=>"67",
     :normalizedrank_sw=>"",
     :newpublicationid_sw=>"",
     :isobsolete_sw=>"false",
     :publisher=>"ELSEVIER SCIENCE BV",
     :city=>"AMSTERDAM",
     :stateprovince=>"",
     :country=>"NETHERLANDS",
     :pages=>"245-259",
     :issn=>"0165-0173",
     :journal=>
      {:name=>"BRAIN RESEARCH REVIEWS",
       :volume=>"47",
       :issue=>"1-3",
       :pages=>"245-259",
       :identifier=>
        [{:type=>"issn",
          :id=>"0165-0173",
          :url=>
           'http://searchworks.stanford.edu/?search_field=advanced&number=0165-0173'},
         {:type=>"doi",
          :id=>"10.1016/j.brainresrev.2004.05.006",
          :url=>"http://dx.doi.org/10.1016/j.brainresrev.2004.05.006"}]},
     :abstract=>
      "Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv",
     :last_updated=>"2013-07-23 22:06:49 UTC",
     :authorship=>
      [{:cap_profile_id=>8804,
        :sul_author_id=>2579,
        :status=>"unknown",
        :visibility=>"private",
        :featured=>false}]
    }
	}

  # describe "#sync_publication_hash" do
  #   context " with multiple contributions " do
  #
  #     it " writes the correct authorship field to the pub_hash "
  #         pending
  #       end
  #     it " creates a new contribution for a new authorship entry in the pub_hash "
  #         pending
  #       end
  #   end
  # end

	describe "#to_mla_citation" do

	  context "with more than 5 authors" do
	    it "builds citations with just the first 5" do
	      h = PubHash.new(pub_hash)
	      cite = h.to_mla_citation
        cite.should =~ /^Sohl, G./
	      cite.should =~ /et al./
	      cite.should_not =~ /Last/
	    end
	  end

	end
end

