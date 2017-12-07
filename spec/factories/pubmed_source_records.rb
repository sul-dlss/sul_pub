# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :pubmed_source_record do
    source_data 'MyText'
    pmid 1
    lock_version 1
    source_fingerprint 'MyString'
    is_active false
  end

  factory :pubmed_source_record_10000166, parent: :pubmed_source_record do
    source_data File.read('spec/fixtures/pubmed/pubmed_record_10000166.xml')
    pmid 10_000_166
    lock_version 0
    source_fingerprint 'ae8df3b2a3b1b14d908656bb6a21a708a218a879ffc930ec9ca4f92968525a07'
    is_active true
  end
end
