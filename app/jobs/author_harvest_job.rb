class AuthorHarvestJob < ActiveJob::Base
  queue_as :default

  # Performs an asynchronous harvest and save for a given Author
  # @param [String] cap_profile_id
  # @param [Boolean] harvest_alternate_names
  # @return [void]
  def perform(cap_profile_id)
    author = Author.find_by(cap_profile_id: cap_profile_id)
    author ||= Author.fetch_from_cap_and_create(cap_profile_id)
    raise "Could not find or fetch author: #{cap_profile_id}" unless author.is_a?(Author)
    AllSources.harvester.process_author(author)
    log_pubs(author)
  rescue => e
    msg = "AuthorHarvestJob.perform(#{cap_profile_id})"
    NotificationManager.log_exception(logger, msg, e)
    Honeybadger.notify(e, context: { message: msg })
    raise
  end

  private

    # @param [Author] author
    # @return [void]
    def log_pubs(author)
      pubs = Contribution.where(author_id: author.id).map(&:publication).each do |p|
        logger.info "publication #{p.id}: #{p.pub_hash[:apa_citation]}"
      end
      logger.info "Number of publications #{pubs.count}"
    end

end
