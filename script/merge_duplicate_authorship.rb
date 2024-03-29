# frozen_string_literal: true

class MergeDuplicateAuthorship
  def initialize
    @log_merge = logger 'duplicate_authorship_merge.log'
    @log_record = logger 'duplicate_authorship_record.log'
    @records_modified = 0
  end

  def logger(filename)
    Logger.new(Rails.root.join('log', filename))
  end

  # Preliminary analysis indicated that all duplicate authorship
  # records did NOT have any duplicates in the source record, so the
  # original fingerprint hash identifiers are valid.  The following code
  # was used to evaluate any duplication in the source records.
  def source_record_authorship_dedup?(pub)
    status = false
    src_records = pub.user_submitted_source_records
    @logger.info "Publication #{pub[:id]}: #{src_records.length} user src records"
    src_records.each do |src|
      src_hash = JSON.parse(src.source_data)
      src_authorship = src_hash['authorship']
      @logger.info "Publication #{pub[:id]}: src_authorship: #{JSON.dump(src_authorship)}"
      next unless src_authorship.length > 1

      src_authorship_ids = src_authorship.pluck('cap_profile_id')
      src_authorship_set = src_authorship_ids.to_set
      next unless src_authorship_set.length != src_authorship_ids.length

      @logger.error "Publication #{pub[:id]}: src_authorship duplicate"
      status = true
      # require 'pry'; binding.pry
      # modify src authorship and recalculate fingerprint?
      # src.source_fingerprint
    end
    status
  end

  # If the pub_hash[:authorship] array contains duplicate values,
  # save it as a set of authorship values.
  def duplicate_authorship?(pub)
    authorship = pub.pub_hash[:authorship]
    if authorship.length > 1
      authorship_ids = authorship.pluck(:cap_profile_id)
      authorship_set = authorship_ids.to_set
      if authorship_set.length != authorship_ids.length
        @logger.warn "Publication #{pub[:id]} should be modified"
        @logger.warn "Publication #{pub[:id]} created_at #{pub[:created_at]}"
        @logger.warn "Publication #{pub[:id]} updated_at #{pub[:updated_at]}"
        @logger.warn "Publication #{pub[:id]} provenance: #{pub.pub_hash[:provenance]}"
        @logger.warn "Publication #{pub[:id]} authorship: #{JSON.dump(authorship)}"
        # Preliminary analysis indicated that all duplicate authorship
        # records did NOT have any duplicates in the source records.
        # source_record_authorship_dedup?(pub)
        return true
      end
    end
    false
  rescue StandardError => e
    msg = "Problem with publication: #{pub[:id]}\n"
    msg += "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    @logger.error msg
  end

  # If the pub_hash[:authorship] array contains duplicate values,
  # save it as a set of authorship values.
  def merge_authorship(pub)
    authorship = pub.pub_hash[:authorship]
    if duplicate_authorship? pub
      # Modify and save the pub_hash without authorship duplicates.
      pub.pub_hash[:authorship] = authorship.to_set.to_a
      pub.pubhash_needs_update!
      if pub.save
        @records_modified += 1
        @logger.info "Publication #{pub[:id]} modified and saved at #{pub[:updated_at]}"
      end
    end
  rescue StandardError => e
    msg = "Problem with publication: #{pub[:id]}\n"
    msg += "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    @logger.error msg
  end

  def diagnostics
    @logger = @log_record
    ActiveRecord::Base.logger.level = 1
    Publication.find_each(batch_size: 500) do |pub|
      duplicate_authorship? pub
    end
  rescue StandardError => e
    msg = "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    @logger.error msg
  end

  def work
    @logger = @log_merge
    ActiveRecord::Base.logger.level = 1
    Publication.find_each(batch_size: 500) do |pub|
      merge_authorship pub
    end
    @logger.info "Records modified: #{@records_modified}"
  rescue StandardError => e
    msg = "#{e.inspect}\n"
    msg += e.backtrace.join("\n")
    @logger.error msg
  end
end

c = MergeDuplicateAuthorship.new
c.work
