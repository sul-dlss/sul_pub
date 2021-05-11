# frozen_string_literal: true

class MissingWosId
  attr_reader :logger

  def initialize
    @logger = Logger.new(Rails.root.join('log', 'missing_wos_id_record.log'))
  end

  # Identify publications without a WosID
  def missing_wos_id?(pub)
    prov = pub.pub_hash[:provenance]
    ids = pub.pub_hash[:identifier]
    if prov =~ /sciencewire/i
      return false if ids.any? { |id| id[:type] =~ /WoS/i }

      authorship = pub.pub_hash[:authorship]
      logger.warn "Publication #{pub.id} should be modified"
      logger.warn "Publication #{pub.id} created_at: #{pub.created_at}"
      logger.warn "Publication #{pub.id} updated_at: #{pub.updated_at}"
      logger.warn "Publication #{pub.id} provenance: #{prov}"
      logger.warn "Publication #{pub.id} identities: #{JSON.dump(ids)}"
      logger.warn "Publication #{pub.id} authorship: #{JSON.dump(authorship)}"
      if pub.publication_identifiers.any? { |id| id.identifier_type =~ /WoS/i }
        logger.warn "Publication #{pub[:id]} has a WoSItemID identity"
      else
        src = SciencewireSourceRecord.find_by_sciencewire_id(pub.sciencewire_id)
        logger.warn "Publication #{pub[:id]} has no WoSItemID in SciencewireSourceRecord" if src.publication.wos_item_id.blank?
      end
      return true
    end
    false
  rescue StandardError => e
    msg = "Problem with publication: #{pub[:id]}\n"
    msg += "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    logger.error msg
  end

  def diagnostics
    ActiveRecord::Base.logger.level = 1
    Publication.find_each(batch_size: 500) do |pub|
      missing_wos_id? pub
    end
  rescue StandardError => e
    msg = "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    logger.error msg
  end

  def work
    ActiveRecord::Base.logger.level = 1
    Publication.where.not(sciencewire_id: nil).find_each(batch_size: 500) do |pub|
      if missing_wos_id? pub
        src = SciencewireSourceRecord.find_by_sciencewire_id(pub.sciencewire_id)
        fingerprint_before = src.source_fingerprint
        src.sciencewire_update
        src.reload
        if src.source_fingerprint != fingerprint_before
          logger.warn "Publication #{pub[:id]} has a new WoSItemID in SciencewireSourceRecord" if src.publication.wos_item_id.present?
          pub.rebuild_pub_hash || raise("Error(s) saving Publication: #{pub.errors}")
          logger.warn "Updated Publication #{pub[:id]} with an updated SciencewireSourceRecord"
        end
      end
    end
  rescue StandardError => e
    msg = "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    logger.error msg
  end
end

c = MissingWosId.new
c.work
