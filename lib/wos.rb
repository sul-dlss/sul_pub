# Web of Science/Knowlege (WOS) utilities
module WOS
  # rubocop:disable Style/ClassVars

  # WIP - commented out to avoid code-coverage failure
  # # @return [WebOfScience::Harvester]
  # def self.harvester
  #   @@harvester ||= WebOfScience::Harvester.new
  # end

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

  # rubocop:enable Style/ClassVars
end
