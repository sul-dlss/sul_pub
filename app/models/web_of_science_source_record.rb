class WebOfScienceSourceRecord < ActiveRecord::Base

  serialize :identifiers, Hash

  validates :active, :database, :source_data, :source_fingerprint, :uid, presence: true

  after_initialize :init

  delegate :doc, to: :record
  delegate :to_xml, to: :record

  # @return [WebOfScience::Record]
  def record
    @record ||= begin
      rec = WebOfScience::Record.new(record: source_data)
      rec.identifiers.update identifiers
      rec
    end
  end

  def wos_item_id
    uid.split(':').last if database == 'WOS'
  end

  private

    def init
      # assume records are active until we discover a deprecation attribute
      self.active = true if attributes.key?('active') && attributes['active'].nil?
      init_from_source if attributes.key?('source_data')
    end

    # Assign default attributes using source_data
    def init_from_source
      raise 'Missing source_data' if source_data.nil?
      self.source_fingerprint = Digest::SHA2.hexdigest(source_data)
      self.database ||= record.database
      self.uid ||= record.uid
      init_optional_attributes
    end

    # Assign optional attributes using source_data
    def init_optional_attributes
      self.doi ||= record.doi if record.doi.present?
      self.pmid ||= record.pmid if record.pmid.present?
    end
end
