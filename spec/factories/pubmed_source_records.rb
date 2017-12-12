# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :pubmed_source_record do
    source_data 'MyText'
    pmid 1
    lock_version 1
    source_fingerprint 'MyString'
    is_active false
  end
end
