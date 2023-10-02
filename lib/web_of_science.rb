# frozen_string_literal: true

# Web of Science (WOS) utilities
module WebOfScience
  # @return [WebOfScience::Harvester]
  def self.harvester
    @@harvester ||= WebOfScience::Harvester.new
  end

  # @return [Clarivate::RestLinksClient]
  def self.links_client
    @@links_client ||= Clarivate::RestLinksClient.new
  end

  # @return [WebOfScience::RestClient]
  def self.client
    @@client ||= Clarivate::RestClient.new
  end

  # @return [WebOfScience::Queries]
  def self.queries
    @@queries ||= WebOfScience::Queries.new
  end

  def self.logger
    @@logger ||= Logger.new(Settings.WOS.LOG)
  end

  # Fetch a single publication and parse and ensure we have a correct response.
  # We check in steps that the response is XML and it includes the correct content.
  def self.working?
    uids = %w[WOS:A1976BW18000001 WOS:A1972N549400003]
    retriever = queries.retrieve_by_id(uids)
    records = retriever.next_batch
    raise 'WebOfScience found no records' unless records.is_a?(WebOfScience::Records) && records.count > 0
    raise 'WebOfScience failed to parse records' unless records.first.is_a?(WebOfScience::Record)

    true
  end
end
