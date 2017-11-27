# Web of Science (WOS) utilities
module WebOfScience
  # rubocop:disable Style/ClassVars

  # @return [WebOfScience::Harvester]
  def self.harvester
    @@harvester ||= WebOfScience::Harvester.new
  end

  # @return [Clarivate::LinksClient]
  def self.links_client
    @@links_client ||= Clarivate::LinksClient.new
  end

  # @return [WebOfScience::Client]
  def self.client
    @@client ||= WebOfScience::Client.new(Settings.WOS.AUTH_CODE)
  end

  # @return [WebOfScience::Queries]
  def self.queries
    @@queries ||= WebOfScience::Queries.new(client)
  end

  def self.logger
    @@logger ||= Logger.new(Settings.WOS.LOG)
  end
  # rubocop:enable Style/ClassVars
end
