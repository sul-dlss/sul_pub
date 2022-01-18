# frozen_string_literal: true

module Mais
  # Service for updating ORCID Ids for Author records.
  class UpdateAuthorsOrcid
    # @param [Array<Mais::Client::OrcidUser] orcid_users to update
    # @param [Logger] logger
    def initialize(orcid_users, logger: nil)
      @orcid_users = orcid_users
      @logger = logger
    end

    def update
      count = 0
      sunetids.each do |sunetid|
        author = Author.find_by(sunetid: sunetid)
        next if author.nil?

        logger&.info("#{self.class} - author #{author.id} - updating orcid id to #{sunetid_to_orcidid[sunetid]}")
        author.update(orcidid: sunetid_to_orcidid[sunetid])
        count += 1
      end
      logger&.info("#{self.class} Updated #{count} author records from #{orcid_users.size} ORCID users.")
      count
    end

    private

    attr_reader :orcid_users, :logger

    def sunetids
      new_sunetids + changed_sunetids + removed_sunetids
    end

    def removed_sunetids
      @removed_sunetids ||= existing_author_orcids.keys - sunetid_to_orcidid.keys
    end

    def new_sunetids
      @new_sunetids ||= sunetid_to_orcidid.keys - existing_author_orcids.keys
    end

    def changed_sunetids
      @changed_sunetids ||= existing_author_orcids.keys.filter do |sunetid|
        sunetid_to_orcidid[sunetid] && sunetid_to_orcidid[sunetid] != existing_author_orcids[sunetid]
      end
    end

    def existing_author_orcids
      @existing_author_orcids ||= Author.where.not(orcidid: nil).pluck(:sunetid, :orcidid).to_h
    end

    def sunetid_to_orcidid
      @sunetid_to_orcidid ||= orcid_users.to_h { |orcid_user| [orcid_user.sunetid, orcid_user.orcidid] }
    end
  end
end
