class AuthorHarvestBaseJob < ActiveJob::Base
  queue_as :default

  # Performs an asynchronous harvest and save for a given Author
  # @param [Author] author
  # @param [Hash] options
  def perform(author, options = {})
    raise "author must be an Author" unless author.is_a?(Author)
    harvest(author, options)
    log_pubs(author)
  rescue => e
    msg = "#{self.class} - author: #{author.cap_profile_id}, options: #{options})"
    NotificationManager.log_exception(logger, msg, e)
    Honeybadger.notify(e, context: { message: msg })
    raise
  end

  private

    # @param [Author] author
    # @param [Hash] options
    def harvest(author, options)
      # subclass implements details
    end

    # @param [Author] author
    # @return [void]
    def log_pubs(author)
      pubs = Contribution.where(author_id: author.id).map(&:publication).each do |p|
        logger.info "publication #{p.id}: #{p.pub_hash[:apa_citation]}"
      end
      logger.info "Number of publications #{pubs.count}"
    end
end
