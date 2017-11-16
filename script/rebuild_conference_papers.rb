class RebuildConferencePapers
  def work
    logger = Logger.new(Rails.root.join('log', 'script_rebuild_conference_papers.log'))
    logger.info "Starting"
    found = 0
    count = 0
    Publication.where.not(sciencewire_id: nil).find_each do |pub|
      begin
        count += 1
        if pub.pub_hash[:type] == Settings.sul_doc_types.inproceedings
          found += 1
          logger.debug "Rebuilding pub_hash for Publication.find(#{pub.id})"
          pub.rebuild_pub_hash # from SciencewireSourceRecord
        end
      rescue => e
        logger.error "Problem with Publication.find(#{pub.id}): #{e.inspect}"
        logger.error e.backtrace.join "\n"
      end
      logger.debug "Processed #{count}" if count % 1000 == 0
    end
    logger.info "Done. Processed #{count}, Found #{found}"
  end
end

RebuildConferencePapers.new.work
