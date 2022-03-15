# frozen_string_literal: true

require 'nokogiri'

class PubmedSourceRecord < ApplicationRecord
  # validates_uniqueness_of :pmid
  # validates_presence_of :source_data

  def self.get_pub_by_pmid(pmid)
    pubmed_record = PubmedSourceRecord.for_pmid(pmid)
    return if pubmed_record.nil?

    pub = Publication.new(
      active: true,
      pmid: pmid,
      pub_hash: Pubmed::MapPubHash.map(source_data)
    )
    pub.sync_publication_hash_and_db
    pub.save
    pub
  end

  def self.for_pmid(pmid)
    find_by(pmid: pmid) || get_pubmed_record_from_pubmed(pmid)
  end

  # @return [PubmedSourceRecord] the recently downloaded pubmed_source_records data
  def self.get_pubmed_record_from_pubmed(pmid)
    return unless Settings.PUBMED.lookup_enabled

    get_and_store_records_from_pubmed([pmid])
    find_by(pmid: pmid)
  end
  private_class_method :get_pubmed_record_from_pubmed

  def self.create_pubmed_source_record(pmid, pub_doc)
    where(pmid: pmid).first_or_create(
      pmid: pmid,
      source_data: pub_doc.to_xml,
      is_active: true,
      source_fingerprint: Digest::SHA2.hexdigest(pub_doc)
    )
  end

  def self.get_and_store_records_from_pubmed(pmids)
    pmidValuesForPost = pmids.uniq.collect { |pmid| "&id=#{pmid}" }.join
    the_incoming_xml = Pubmed.client.fetch_records_for_pmid_list pmidValuesForPost
    source_records = Nokogiri::XML(the_incoming_xml).xpath('//PubmedArticle').map do |pub_doc|
      pmid = pub_doc.xpath('MedlineCitation/PMID').text
      begin
        PubmedSourceRecord.new(
          pmid: pmid,
          source_data: pub_doc.to_xml,
          is_active: true,
          source_fingerprint: Digest::SHA2.hexdigest(pub_doc)
        )
      rescue StandardError => e
        NotificationManager.error(e, "Cannot create PubmedSourceRecord with pmid: #{pmid}", self)
      end
    end
    import source_records.compact
  end
  private_class_method :get_and_store_records_from_pubmed

  # Retrieve this pubmed record from PubMed and update
  # is_active, source_data and the source_fingerprint fields.
  # Used to update the pubmed source record on our end
  # @return [Boolean] the return value from update!
  def pubmed_update
    return false unless Settings.PUBMED.lookup_enabled

    pubmed_source_xml = Pubmed.client.fetch_records_for_pmid_list pmid
    pub_doc = Nokogiri::XML(pubmed_source_xml).xpath('//PubmedArticle')[0]
    return false unless pub_doc

    attrs = {}
    attrs[:source_data] = pub_doc.to_xml
    attrs[:source_fingerprint] = Digest::SHA2.hexdigest(pub_doc)
    update! attrs
  end
end
