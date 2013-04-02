class AuthorIdentifier < ActiveRecord::Base
  attr_accessible :author_id, :identifier_type, :identifier_value
  belongs_to :author
end
