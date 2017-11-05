FactoryGirl.define do
  factory :publication_identifier do
    publication
    after(:create) do |pub_id|
      pub = pub_id.publication
      pub.pub_hash[:identifier] ||= []
      pub.pub_hash[:identifier] << pub_id.identifier
      pub.save
    end
  end

  factory :blank_publication_identifier, parent: :publication_identifier do
    identifier_type 'blank'
  end

  # ---
  # DOI

  factory :doi_publication_identifier, parent: :publication_identifier do
    identifier_type 'doi'
    identifier_value '10.1038/ncomms3199'
    identifier_uri 'http://dx.doi.org/10.1038/ncomms3199'
  end

  factory :doi_empty_publication_identifier, parent: :publication_identifier do
    identifier_type 'doi'
  end

  factory :doi_empty_uri_publication_identifier, parent: :publication_identifier do
    identifier_type 'doi'
    identifier_value '10.1038/ncomms3199'
  end

  factory :doi_empty_value_publication_identifier, parent: :publication_identifier do
    identifier_type 'doi'
    identifier_uri 'http://dx.doi.org/10.1038/ncomms3199'
  end

  # Altmetrics identifiers gem normalizes this value to:
  # > Identifiers::DOI.extract 'http://dx.doi.org/10.1038/ncomms3199'
  # => ["10.1038/ncomms3199"]
  factory :doi_denormalized_value_publication_identifier, parent: :publication_identifier do
    identifier_type 'doi'
    identifier_value 'http://dx.doi.org/10.1038/ncomms3199'
  end

  # Altmetrics identifiers gem indicates this is invalid data:
  # > Identifiers::DOI.extract '10.1038/'
  # => []
  factory :doi_invalid_publication_identifier, parent: :publication_identifier do
    identifier_type 'doi'
    identifier_value '10.1038/'
  end

  # ---
  # ISBN

  factory :isbn_publication_identifier, parent: :publication_identifier do
    identifier_type 'isbn'
    identifier_value '9781931368223'
  end

  # Altmetrics identifiers gem normalizes this value to:
  # > Identifiers::ISBN.extract " 0-7623-1435-4"
  # => ["9780762314355"]
  factory :isbn_denormalized_value_publication_identifier, parent: :publication_identifier do
    identifier_type 'isbn'
    identifier_value ' 0-7623-1435-4'
  end

  # Altmetrics identifiers gem indicates this is invalid data:
  # > Identifiers::ISBN.extract "ISBN99999"
  # => []
  factory :isbn_invalid_publication_identifier, parent: :publication_identifier do
    identifier_type 'isbn'
    identifier_value 'ISBN99999'
  end

  # ---
  # SULPubId

  factory :sul_publication_identifier, parent: :publication_identifier do
    identifier_type 'SULPubId'
    identifier_value '170485'
    identifier_uri 'http://sulcap.stanford.edu/publications/170485'
  end

  # ---
  # PMID

  factory :pmid_publication_identifier, parent: :publication_identifier do
    identifier_type 'PMID'
    identifier_value '10002407'
    identifier_uri 'https://www.ncbi.nlm.nih.gov/pubmed/10002407'
  end

  # ---
  # PublicationItemID

  factory :publicationItemID_publication_identifier, parent: :publication_identifier do
    identifier_type 'PublicationItemID'
    identifier_value '10000593'
  end
end
