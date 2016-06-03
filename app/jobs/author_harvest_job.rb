class AuthorHarvestJob < ActiveJob::Base
  queue_as :default

  ##
  # Performs an asynchronous harvest and save for a given Author
  # @param [String] cap_profile_id
  # @param [Boolean] harvest_alternate_names
  def perform(cap_profile_id, harvest_alternate_names: false)
    harvester = ScienceWireHarvester.new
    harvester.use_author_identities = harvest_alternate_names
    author = Author.where(cap_profile_id: cap_profile_id).first
    author ||= Author.fetch_from_cap_and_create(cap_profile_id)
    harvester.harvest_pubs_for_author_ids author.id
    pubs = Contribution.where(author_id: author.id).map(&:publication).each do |p|
      logger.info "publication #{p.id}: #{p.pub_hash[:apa_citation]}"
    end
    logger.info "Number of publications #{pubs.count}"
  rescue => e
    msg = "AuthorHarvestJob.perform(cap_profile_id=#{cap_profile_id}, harvest_alternate_names=#{harvest_alternate_names})"
    NotificationManager.log_exception(logger, msg, e)
    NotificationManager.notify_squash(e, msg)
    raise
  end
end
