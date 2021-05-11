# frozen_string_literal: true

# a class that will harvest from all sources, useful for the regular cron jobs
module AllSources
  class Harvester < ::Harvester::Base
    # Harvest all publications for an author from all sources
    # @param [Author] author
    # @param [Hash] options
    # @return [Array<String>] WosUIDs that create Publications
    def process_author(author, options = {})
      raise(ArgumentError, 'author must be an Author') unless author.is_a? Author

      WebOfScience.harvester.process_author(author, options) if Settings.WOS.enabled
      Pubmed.harvester.process_author(author, options) if Settings.PUBMED.harvest_enabled
    rescue StandardError => e
      NotificationManager.error(e, "#{self.class} - harvest all sources failed for author #{author.id}", self)
    end

    delegate :logger, to: :AllSources
  end
end
