# frozen_string_literal: true

module Orcid
  # Application logic to harvest publications from ORCID.org;
  # This is the bridge between the ORCID.org API and the SUL-PUB application.
  class Harvester < ::Harvester::Base
    # Harvest all publications for an author from ORCID.org
    # @param [Author] author
    # @param [Hash] _options
    # @return [Array<String>] put-codes that create Publications
    def process_author(author, _options = {})
      return [] unless check_orcidid?(author)

      log_info(author, "processing author #{author.id} - #{author.orcidid}")

      works_response = client.fetch_works(author.orcidid)

      return [] unless check_last_modified?(author, works_response)

      put_codes = process_works(author, works_response[:group])

      if put_codes.present?
        author.orcid_last_modified = works_response['last-modified-date']['value']
        author.save!
      end

      put_codes
    rescue StandardError => e
      NotificationManager.error(e, "#{self.class} - Orcid.org harvest failed for author #{author.id}", self)
      []
    end

    private

    delegate :logger, :client, to: :Orcid

    def check_orcidid?(author)
      return true if author.orcidid

      log_info(author, "skipping author #{author.id}")
      false
    end

    def check_last_modified?(author, works_response)
      return true if author.orcid_last_modified != works_response['last-modified-date']['value']

      log_info(author, "skipping author #{author.id}, since works have not changed")
      false
    end

    def check_work_type?(author, work)
      return true if PublicationTypeMapper.work_type?(work.work_type)

      log_info(author, "skipping work #{work.put_code} since work type #{work.work_type} not supported.")
      false
    end

    def check_external_ids?(author, work)
      return true unless filtered_external_ids(work).empty?

      log_info(author, "skipping work #{work.put_code} since no identifiers.")
      false
    end

    def process_works(author, groups_response)
      groups_response.map { |work_response| process_work(author, work_response) }.compact
    end

    def process_work(author, work_summary_response)
      # Using first work summary only.
      work_summary = WorkRecord.new(work_summary_response['work-summary'][0])

      return unless check_work_type?(author, work_summary) && check_external_ids?(author, work_summary)

      log_info(author, "processing work #{work_summary.put_code}")

      publication = find_or_create_publication(author, work_summary)
      author.assign_pub(publication, orcid_put_code: work_summary.put_code) unless publication.authors.include?(author)

      work_summary.put_code
    end

    def find_or_create_publication(author, work_summary)
      find_matching_publication(work_summary) || create_publication(author.orcidid, work_summary.put_code)
    end

    def create_publication(orcidid, put_code)
      # Fetch complete Work record.
      work_response = client.fetch_work(orcidid, put_code)
      work = WorkRecord.new(work_response)

      source = new_orcid_source_record(orcidid, put_code, work_response)
      pub = new_publication(work, source)
      pub.sync_publication_hash_and_db
      pub.save!
      pub
    end

    def new_orcid_source_record(orcidid, put_code, work_response)
      OrcidSourceRecord.new(
        put_code: put_code,
        orcidid: orcidid,
        last_modified_date: work_response['last-modified-date']['value'],
        source_data: work_response,
        source_fingerprint: Digest::SHA2.hexdigest(JSON.generate(work_response))
      )
    end

    def new_publication(work, source)
      Publication.new(
        active: true,
        pub_hash: WorkMapper.map(work),
        orcid_source_record: source
      )
    end

    def find_matching_publication(work_summary)
      filtered_external_ids(work_summary).map do |external_id|
        PublicationIdentifier.find_by(identifier_type: IdentifierTypeMapper.to_sul_pub_id_type(external_id.type),
                                      identifier_value: external_id.value)&.publication
      end.compact.first
    end

    def filtered_external_ids(work_summary)
      # Filtering ISSNs, since they are for the journal/serial not the publication.
      work_summary.external_ids.reject { |external_id| external_id.type == 'issn' }
    end
  end
end
