# Pubmed utilities
module Pubmed

  # @return [Pubmed::Harvester]
  def self.harvester
    @@harvester ||= Pubmed::Harvester.new
  end

  # @return [Pubmed::Client]
  def self.client
    @@client ||= Pubmed::Client.new
  end

  def self.logger
    @@logger ||= Logger.new(Settings.PUBMED.LOG)
  end

  # Fetch a single publication and parse and ensure we have a correct response.
  # We check in steps that the response is XML and it includes the correct content.
  def self.working?
    response = client.fetch_records_for_pmid_list('22895186')
    response.is_a?(String) &&
      response.include?('<PubmedArticleSet>') &&
      (doc = Nokogiri::XML(response)).is_a?(Nokogiri::XML::Document) &&
      doc.at_xpath('/PubmedArticleSet/PubmedArticle/MedlineCitation/PMID/text()').to_s == '22895186' &&
      doc.at_xpath('//LastName[text()="Hardy"]').is_a?(Nokogiri::XML::Element)
  end
end
