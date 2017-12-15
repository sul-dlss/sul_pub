class WebOfScienceSourceRecord < ActiveRecord::Base

  validates :active, :database, :source_data, :source_fingerprint, :uid, presence: true

  after_initialize :init

  delegate :doc, to: :record
  delegate :to_xml, to: :record

  # @return [WebOfScience::Record]
  def record
    @record ||= WebOfScience::Record.new(record: source_data)
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
      self.database ||= record.database
      self.source_fingerprint ||= Digest::SHA2.hexdigest(source_data)
      self.uid ||= record.uid
    end

end
