require 'spec_helper'

describe ScienceWireClient do
  let(:science_wire_client) { ScienceWireClient.new }
  describe '#query_sciencewire_by_author_name' do
    context 'with common last name, first name' do
      it 'returns a list of 12 sciencewire ids' do
        VCR.use_cassette('sciencewire_client_spec_returns_list_of_4') do
          expect(science_wire_client.query_sciencewire_by_author_name('james', '', 'smith').size).to eq(10)
        end
      end
    end
    context 'with uncommon last name, first name, and max rows 4' do
      it 'returns an empty array' do
        VCR.use_cassette('sciencewire_client_spec_returns_empty_array') do
          expect(science_wire_client.query_sciencewire_by_author_name('yukon', '', 'ottawa', 4).size).to eq(0)
        end
      end
    end
  end

  describe '#get_sciencewire_id_suggestions' do
    it 'returns suggestions for email address and name' do
      VCR.use_cassette('sciencewire_client_spec_returns_suggestions_for_email') do
        seeds = [5_199_247, 7_877_232, 844_542, 1_178_390, 29_434_219, 30_072_480, 30_502_634, 46_558_063, 31_222_988]

        expect(
          science_wire_client
            .get_sciencewire_id_suggestions('edler', 'alice', '', 'alice.edler@stanford.edu', seeds).size)
          .to be >= 4
      end
    end

    it 'gets suggestions from journals' do
      VCR.use_cassette('sciencewire_client_spec_searches_journals_and_proceedings') do
        seeds = [532_237, 29_681_830, 29_693_742, 30_153_017, 30_563_572, 30_711_058, 30_991_998, 31_488_302, 31_623_382, 32_897_909,
                 33_038_883, 33_139_791, 33_878_760, 47_444_872, 53_640_378, 54_368_177, 59_612_803, 59_641_485, 60_094_854, 60_223_059, 60_478_790,
                 62_816_475, 62_823_609, 62_903_742, 63_182_944, 62_767_480, 59_904_158, 37_634_308, 63_378_178, 63_775_722, 63_911_215, 4_167_402, 63_891_331,
                 63_814_446, 62_976_803, 59_811_972, 59_878_565, 37_635_302, 59_936_785, 37_630_237, 37_632_866, 59_839_380, 29_114_844, 24_672_363, 22_528_207,
                 22_411_820, 21_667_389, 64_357_283, 27_876_654, 16_447_626, 34_333_979, 21_865_294, 22_624_536, 23_216_217, 24_575_036, 35_196_221, 2_627_002,
                 3_769_378, 3_704_704, 4_513_632, 6_434_468, 6_368_152, 571_008, 35_566_141, 36_119_242, 6_008_013, 36_234_880, 36_225_095, 36_139_437, 36_127_090,
                 36_208_464, 35_640_871, 23_804_292, 22_654_678, 17_870_903, 23_364_040, 45_141_719, 64_799_575, 65_697_723, 66_020_502, 67_583_123]

        expect(
          science_wire_client
            .get_sciencewire_id_suggestions('benson', 'sally', '', 'smbenson@stanford.edu', seeds).size)
          .to be >= 111
      end
    end
  end

  describe '#get_full_sciencewire_pubs_for_wos_ids' do
    it 'returns a Nokogiri::XML::Document containing all SW pubs when passed an array of WebOfScience ids' do
      VCR.use_cassette('sciencewire_client_spec_gets_sw_pubs_with_wos_ids') do
        doc = science_wire_client.get_full_sciencewire_pubs_for_wos_ids(%w(000318550800072 000317872800004 000317717300006))
        expect(doc).to be_a(Nokogiri::XML::Document)
        expect(doc.xpath('//PublicationItem').size).to eq(3)
      end
    end
  end

  describe '#get_pub_by_doi' do
    it 'returns an array with one pubhash' do
      VCR.use_cassette('sciencewire_client_spec_get_pub_by_doi') do
        result = science_wire_client.get_pub_by_doi '10.1111/j.1444-0938.2010.00524.x'
        expect(result).to be_an(Array)
        expect(result.first[:sw_id]).to eq('37929883')
      end
    end
  end

  describe '#pull_records_from_sciencewire_for_pmids' do
  end

  describe '#query_sciencewire_for_publication' do
  end

  describe '#query_sciencewire' do
  end

  describe '#get_full_sciencewire_pubs_for_sciencewire_ids' do
  end

  describe '#get_sw_xml_source_for_sw_id' do
  end
end
