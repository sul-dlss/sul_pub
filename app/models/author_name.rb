class AuthorName < ActiveRecord::Base
  attr_accessible :author_id, :first_name, :last_name, :middle_name
  belongs_to :author
end
