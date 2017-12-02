# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sciencewire_source_record do
    sciencewire_id      1
    source_data         'MyText'
    pmid                1
    lock_version        1 # XXX: unknown how this is actually used or what it means
    source_fingerprint  'MyString'
    is_active           true # XXX: model always has this as true
    created_at          { DateTime.current }
    updated_at          { DateTime.current }
  end
end

def build_sciencewire_source_record_from_fixture(sciencewire_id)
  doc = Nokogiri::XML(File.read("spec/fixtures/sciencewire_source_record/#{sciencewire_id}.xml"))
  record = build(:sciencewire_source_record,
                 source_data: doc.to_xml,
                 sciencewire_id: sciencewire_id,
                 pmid: doc.at_xpath('//PublicationItem/PMID').text.to_i)
  record.source_fingerprint = SciencewireSourceRecord.get_source_fingerprint(record.source_data)
  record
end
