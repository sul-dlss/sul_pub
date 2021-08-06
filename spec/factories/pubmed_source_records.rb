# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :pubmed_source_record do
    source_data { 'MyText' }
    pmid { 1 }
    lock_version { 1 }
    source_fingerprint { 'MyString' }
    is_active { false }
  end

  factory :pubmed_source_record_10000166, parent: :pubmed_source_record do
    source_data { File.read('spec/fixtures/pubmed/pubmed_record_10000166.xml') }
    pmid { 10_000_166 }
    lock_version { 0 }
    source_fingerprint { 'ae8df3b2a3b1b14d908656bb6a21a708a218a879ffc930ec9ca4f92968525a07' }
    is_active { true }
  end

  factory :pubmed_source_record_29279863, parent: :pubmed_source_record do
    source_data { File.read('spec/fixtures/pubmed/pubmed_record_29279863.xml') }
    pmid { 29_279_863 }
    lock_version { 0 }
    source_fingerprint { '39931f05642e1138741a1661a7a777a234b98268ebdf9a925106644e9f0442b2' }
    is_active { true }
  end

  factory :pubmed_source_record_23388678, parent: :pubmed_source_record do
    source_data { File.read('spec/fixtures/pubmed/pubmed_record_23388678.xml') }
    pmid { 23_388_678 }
    lock_version { 0 }
    source_fingerprint { '6d2e133796313c88617abd86bf528dccd5bb85059c0a2bb7eef0407ce0575999' }
    is_active { true }
  end
end
