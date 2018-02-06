module WebOfScience
  # This module complements the WebOfScience::Harvester to retrieve Links-API data
  module ProcessLinks
    class << self
      # Integrate a batch of publication identifiers for WOS records from the Links-API
      # Modifies the record.identifiers for each record in records if their database is 'WOS'
      # @param [Enumerable<WebOfScience::Record>] records
      # @return [void]
      def process_links(records)
        wos_records = records.select { |rec| rec.database == 'WOS' }
        links = retrieve_links(wos_records)
        wos_records.each { |rec| update_links(rec, links[rec.uid]) }
      rescue StandardError => err
        message = "ProcessLinks.process_links failed"
        NotificationManager.error(err, message, self)
      end

      # @param records [Enumerable<WebOfScience::Record>]
      # @return [Hash<String => Hash<String => String>>]
      # @example {"WOS:000288663100014"=>{"pmid"=>"21253920", "doi"=>"10.1007/s12630-011-9462-1"}}
      def retrieve_links(records)
        WebOfScience.links_client.links records.map(&:uid)
      rescue StandardError => err
        message = "ProcessLinks.retrieve_links failed"
        NotificationManager.error(err, message, self)
      end

      # @param record [WebOfScience::Record]
      # @param links [Hash<String => String>] other identifiers (from Links API)
      # @return [void]
      def update_links(record, links)
        record.identifiers.update links
      rescue StandardError => err
        message = "ProcessLinks.update_links for #{record.uid} failed"
        NotificationManager.error(err, message, self)
      end
    end
  end
end
