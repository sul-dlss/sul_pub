module ScienceWire
  class AuthorHarvestJob < AuthorHarvestBaseJob
    queue_as :sw_author_harvest

    private

      # @param [Author] author
      # @param [hash] options
      # @return [void]
      def harvest(author, options)
        return unless Settings.SCIENCEWIRE.enabled
        harvester = ScienceWireHarvester.new
        harvester.use_author_identities = options[:alternate_names] || false
        harvester.harvest_pubs_for_author_ids author.id
      end
  end
end
