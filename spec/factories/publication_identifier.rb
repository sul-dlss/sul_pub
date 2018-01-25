FactoryBot.define do
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

  factory :doi_pub_id, aliases: [:doi_publication_identifier], parent: :publication_identifier do
    identifier_type 'doi'
    identifier_value '10.1038/ncomms3199'
    identifier_uri { identifier_value ? "http://dx.doi.org/#{identifier_value}" : nil }
  end

  factory :isbn_publication_identifier, parent: :publication_identifier do
    identifier_type 'isbn'
    identifier_value '9781931368223'
  end

  # Altmetrics identifiers gem normalizes this value to:
  # > Identifiers::ISBN.extract " 0-7623-1435-4"
  # => ["9780762314355"]
  # factory :isbn_denormalized_value_publication_identifier, parent: :isbn_publication_identifier do
  #   identifier_value ' 0-7623-1435-4'
  # end
  #
  # Altmetrics identifiers gem indicates this is invalid data:
  # > Identifiers::ISBN.extract "ISBN99999"
  # => []
  # factory :isbn_invalid_publication_identifier, parent: :isbn_publication_identifier do
  #   identifier_value 'ISBN99999'
  # end

  factory :sul_publication_identifier, parent: :publication_identifier do
    identifier_type 'SULPubId'
    identifier_value '170485'
    identifier_uri { identifier_value ? "http://sulcap.stanford.edu/publications/#{identifier_value}" : nil }
  end

  factory :pmid_publication_identifier, parent: :publication_identifier do
    identifier_type 'PMID'
    identifier_value '10002407'
    identifier_uri { identifier_value ? "https://www.ncbi.nlm.nih.gov/pubmed/#{identifier_value}" : nil }
  end

  factory :publicationItemID_publication_identifier, parent: :publication_identifier do
    identifier_type 'PublicationItemID'
    identifier_value '10000593'
  end
end
