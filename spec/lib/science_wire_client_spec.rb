require 'spec_helper'

describe ScienceWireClient do
	let(:science_wire_client) {ScienceWireClient.new}
	describe "#query_sciencewire_by_author_name" do
		context "with common last name, first name" do

			it "returns a list of 12 sciencewire ids" do
				VCR.use_cassette("sciencewire_client_spec_returns_list_of_4") do
					expect(science_wire_client.query_sciencewire_by_author_name("james", "", "smith").size).to eq(10)
				end
			end

		end
		context "with uncommon last name, first name, and max rows 4" do

			it "returns an empty array" do
				VCR.use_cassette("sciencewire_client_spec_returns_empty_array") do
					expect(science_wire_client.query_sciencewire_by_author_name("yukon", "", "ottawa", 4).size).to eq(0)
				end
			end

		end
	end

	describe "#get_sciencewire_id_suggestions" do

		it "returns suggestions for email address and name" do
      VCR.use_cassette("sciencewire_client_spec_returns_suggestions_for_email") do
        seeds = [ 5199247,7877232,844542,1178390,29434219,30072480,30502634,46558063,31222988]

        expect(
          science_wire_client.
            get_sciencewire_id_suggestions("edler", "alice", "", "alice.edler@stanford.edu", seeds).size).
          to be >= 4
      end
		end

		it "gets suggestions from journals" do
      VCR.use_cassette("sciencewire_client_spec_searches_journals_and_proceedings") do
        seeds = [532237,29681830,29693742,30153017,30563572,30711058,30991998,31488302,31623382,32897909,
          33038883,33139791,33878760,47444872,53640378,54368177,59612803,59641485,60094854,60223059,60478790,
          62816475,62823609,62903742,63182944,62767480,59904158,37634308,63378178,63775722,63911215,4167402,63891331,
          63814446,62976803,59811972,59878565,37635302,59936785,37630237,37632866,59839380,29114844,24672363,22528207,
          22411820,21667389,64357283,27876654,16447626,34333979,21865294,22624536,23216217,24575036,35196221,2627002,
          3769378,3704704,4513632,6434468,6368152,571008,35566141,36119242,6008013,36234880,36225095,36139437,36127090,
          36208464,35640871,23804292,22654678,17870903,23364040,45141719,64799575,65697723,66020502,67583123]

        expect(
          science_wire_client.
            get_sciencewire_id_suggestions("benson", "sally", "", "smbenson@stanford.edu", seeds).size).
          to be >= 111
      end
		end

	end

	describe "#get_full_sciencewire_pubs_for_wos_ids" do

	  it "returns a Nokogiri::XML::Document containing all SW pubs when passed an array of WebOfScience ids" do
	    VCR.use_cassette("sciencewire_client_spec_gets_sw_pubs_with_wos_ids") do
	      doc = science_wire_client.get_full_sciencewire_pubs_for_wos_ids(['000318550800072', '000317872800004', '000317717300006'])
				expect(doc).to be_a(Nokogiri::XML::Document)
				expect(doc.xpath('//PublicationItem').size).to eq(3)
			end
	  end

	end

	describe "#get_pub_by_doi" do
	  it "returns an array with one pubhash" do
	    VCR.use_cassette('sciencewire_client_spec_get_pub_by_doi') do
	      result = science_wire_client.get_pub_by_doi '10.1111/j.1444-0938.2010.00524.x'
	      expect(result).to be_an(Array)
	      expect(result.first[:sw_id]).to eq('37929883')
	    end
	  end
	end

	describe "#pull_records_from_sciencewire_for_pmids" do

	end

	describe "#query_sciencewire_for_publication" do

	end

	describe "#query_sciencewire" do

	end

	describe "#get_full_sciencewire_pubs_for_sciencewire_ids" do

	end

	describe "#get_sw_xml_source_for_sw_id" do

	end

end