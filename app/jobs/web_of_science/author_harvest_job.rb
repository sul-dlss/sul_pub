module WebOfScience
  class AuthorHarvestJob < AuthorHarvestBaseJob
    queue_as :wos_author_harvest

    private

      # @param [Author] author
      # @param [Hash] options
      # @return [void]
      def harvest(author, options)
        return unless Settings.WOS.enabled
        WebOfScience.harvester.process_author(author, options)
      end
  end
end
