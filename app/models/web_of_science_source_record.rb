class WebOfScienceSourceRecord < ActiveRecord::Base
  validates :active, :database, :source_data, :source_fingerprint, :uid, presence: true

  # Because of harvest code, the order of events is:
  #   1. WebOfScienceSourceRecord created
  #   2. Publication created, source record updated

  belongs_to :publication, inverse_of: :web_of_science_source_record

  before_validation :extract
  delegate :doc, :to_xml, to: :record

  attr_writer :record

  # @return [WebOfScience::Record]
  def record
    @record ||= WebOfScience::Record.new(record: source_data)
  end

  # @param [Publication] pub must already be persisted, like any association.create
  def link_publication(pub)
    transaction do
      self.publication = pub
      save!
      pub.update(wos_uid: uid)
    end
  end

  private

    # Can initialize with either source_data String or record (WebOfScience::Record)
    def extract
      # assume records are active until we discover a deprecation attribute
      self.active = true if attributes.key?('active') && attributes['active'].nil?
      if source_data.blank?
        return if @record.blank? # nothing to extract
        self.source_data = @record.to_xml
      end
      self.source_fingerprint ||= Digest::SHA2.hexdigest(source_data)
      self.database ||= record.database
      self.uid ||= record.uid
      self.doi ||= record.doi if record.doi.present?
      self.pmid ||= record.pmid if record.pmid.present?
    end
end
