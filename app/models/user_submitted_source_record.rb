class UserSubmittedSourceRecord < ActiveRecord::Base
  attr_accessible :is_active, :lock_version, :source_data, :source_fingerprint, :publication_id, :author_id


  belongs_to :publication

  # Could these become just a join on the publication? probably.
  attr_reader :title, :year

  def self.matches_title title
    where(arel_table[:title].matches("%#{title}%"))
  end

  def self.with_year year
    where(:year => year)
  end

  before_save do
    self.title = publication.title
    self.year  = publication.year
  end
end
