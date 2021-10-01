# frozen_string_literal: true

module Orcid
  # Service for adding works to a researcher's ORCID profile.
  class AddWorks
    # @param [Logger] logger
    def initialize(logger: nil)
      @logger = logger
    end

    # @param [Array<Mais::Client::OrcidUser>] orcid_users to add works for
    # @return [Integer] count of works added.
    def add_all(orcid_users)
      count = orcid_users.map { |orcid_user| add_for_orcid_user(orcid_user) }.sum
      logger&.info("#{self.class} Updated #{count} contributor records from #{orcid_users.size} ORCID users.")
      count
    end

    # @param [Mais::Client::OrcidUser] orcid_user to add works for
    # @return [Integer] count of works added.
    def add_for_orcid_user(orcid_user)
      return 0 unless orcid_user.update?

      author = Author.find_by(sunetid: orcid_user.sunetid)
      return 0 if author.nil? || author.cap_visibility != 'public'

      logger&.info("#{self.class} - author #{author.id} - adding publications to #{orcid_user.orcidid}")

      contributions = Contribution.where(author: author, status: 'approved', visibility: 'public', orcid_put_code: nil)
      contributions.map { |contribution| add_work(author, contribution, orcid_user) ? 1 : 0 }.sum
    end

    private

    attr_reader :logger

    # @return [Boolean] true if work added.
    # rubocop:disable Metrics/AbcSize
    def add_work(author, contribution, orcid_user)
      work = Orcid::PubMapper.map(contribution.publication.pub_hash)
      contribution.orcid_put_code = Orcid.client.add_work(orcid_user.orcidid, work, orcid_user.access_token)
      contribution.save!
      logger&.info("#{self.class} - author #{author.id} - added publication #{contribution.publication.id} with put-code #{contribution.orcid_put_code}")
      true
    rescue Orcid::PubMapper::PubMapperError, Orcid::Client::InvalidTokenError => e
      logger&.warn("#{self.class} - author #{author.id} - did not add publication #{contribution.publication.id}: #{e.message}")
      false
    rescue StandardError => e
      logger&.error("#{self.class} - author #{author.id} - error publication #{contribution.publication.id}: #{e.message}")
      NotificationManager.error(e, "#{self.class} - author #{author.id} - error publication #{contribution.publication.id}: #{e.message}", self)
      false
    end
  end
  # rubocop:enable Metrics/AbcSize
end
