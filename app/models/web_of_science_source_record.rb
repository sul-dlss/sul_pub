class WebOfScienceSourceRecord < ActiveRecord::Base
  validates :active, :database, :source_data, :source_fingerprint, :uid, presence: true

  # Because of harvest code, the order of events is:
  #   1. WebOfScienceSourceRecord created
  #   2. Publication created, source record updated

  belongs_to :publication, inverse_of: :web_of_science_source_record

  after_initialize :init
  delegate :doc, :to_xml, to: :record

  # @return [WebOfScience::Record]
  def record
    @record ||= WebOfScience::Record.new(record: source_data)
  end

  private

    def init
      # assume records are active until we discover a deprecation attribute
      self.active = true if attributes.key?('active') && attributes['active'].nil?
      return unless attributes.key?('source_data') # support .select(...)
      raise 'Missing source_data' if source_data.nil? # otherwise require data
      self.source_fingerprint ||= Digest::SHA2.hexdigest(source_data)
      self.database ||= record.database
      self.uid ||= record.uid
      self.doi ||= record.doi if record.doi.present?
      self.pmid ||= record.pmid if record.pmid.present?
    end
end
