class WebOfScienceSourceRecord < ActiveRecord::Base

  validates :active, :database, :source_data, :source_fingerprint, :uid, presence: true

  after_initialize :check_source_data

  # @return [Nokogiri::XML::Document] XML document
  def doc
    @doc ||= Nokogiri::XML(source_data)
  end

  def active
    # assume records are active until we discover a deprecation attribute
    super || self.active = true
  end

  def database
    super || begin
      uid_split = uid.split(':')
      self.database = uid_split.length > 1 ? uid_split[0] : nil
    end
  end

  # @return [WebOfScience::Record]
  def record
    @record ||= WebOfScience::Record.new(record: source_data)
  end

  def source_fingerprint
    super || self.source_fingerprint = Digest::SHA2.hexdigest(source_data)
  end

  # @return [String] XML
  def to_xml
    doc.to_xml(save_with: XML_OPTIONS).strip
  end

  def uid
    super || self.uid = doc.search('UID').text
  end

  private

    XML_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

    def check_source_data
      raise 'Missing source_data' if source_data.nil?
    end

end
