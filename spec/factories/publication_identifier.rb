FactoryGirl.define do
  factory :publication_identifier do
    publication
  end

  factory :blank_publication_identifier, parent: :publication_identifier do
    identifier_type 'blank'
    identifier_value ''
    identifier_uri ''
  end
end
