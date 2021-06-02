# frozen_string_literal: true

module Orcid
  # Service for deleting works from a researcher's ORCID profile.
  class DeleteWorks
    # @param [Logger] logger
    def initialize(logger: nil)
      @logger = logger
    end

    # @param [Mais::Client::OrcidUser] orcid_user to delete for
    # @return [Integer] count of works deleted.
    def delete_for_orcid_user(orcid_user)
      author = Author.find_by(sunetid: orcid_user.sunetid)
      return 0 if author.nil?

      logger&.info("#{self.class} - author #{author.id} - deleting publications from #{orcid_user.orcidid}")

      contributions = Contribution.where(author: author).where.not(orcid_put_code: nil)
      contributions.map { |contribution| delete_work(contribution, orcid_user) ? 1 : 0 }.sum
    end

    # @param [Contribution] contribution
    # @param [Mais::Client::OrcidUser] orcid_user to delete for
    # @return [Boolean] true if work deleted.
    def delete_work(contribution, orcid_user)
      return false unless orcid_user.update?
      return false unless contribution.orcid_put_code

      response = Orcid.client.delete_work(orcid_user.orcidid, contribution.orcid_put_code, orcid_user.access_token)
      if response
        logger&.info("#{self.class} - author #{contribution.author.id} - deleted work for publication #{contribution.publication.id} " \
          "with put-code #{contribution.orcid_put_code}")
      else
        logger&.info("#{self.class} - author #{contribution.author.id} - work for publication #{contribution.publication.id} " \
          "with put-code #{contribution.orcid_put_code} already deleted")
      end
      contribution.orcid_put_code = nil
      contribution.save!
      response
    rescue StandardError => e
      NotificationManager.error(e, "#{self.class} - author #{contribution.author.id} - error publication #{contribution.publication.id}: #{e.message}", self)
      false
    end

    private

    attr_reader :logger
  end
end
