require 'csv'

class MergeDuplicateAuths
  CONTRIB_CHECK = true

  def initialize
    @logger = Logger.new(Rails.root.join('log', 'merge_duplicate_auths.log'))
    @clones_removed = 0
    @contribs_fixed = 0
  end

  # Change author ids of publications from dups to the master
  # Destory duplicate auth rows
  # Rebuild the publications
  def merge(cap_id)
    moved_contribs = false
    auths = Author.where(cap_profile_id: cap_id)
    master = auths.shift

    auths.each do |clone|
      if CONTRIB_CHECK
        clone.contributions.each do |contrib|
          next if master.contributions.where(publication_id: contrib.publication_id).exists?

          new_contrib = contrib.dup
          new_contrib.author_id = master.id
          new_contrib.save

          @logger.info "Moved pub #{contrib.publication_id} to auth: #{master.id}"
          @contribs_fixed += 1
          moved_contribs = true
        end
      end

      clone.destroy
      @clones_removed += 1
    end

    master.reload if moved_contribs
    master.publications.each do |pub|
      pub.sync_publication_hash_and_db
      pub.save
    end
  rescue ActiveRecord::RecordNotFound
    @logger.warn "Author id not found #{auth_id}"
  end

  def work
    ActiveRecord::Base.logger.level = 1
    count = 0
    dup_cap_ids = JSON.parse(IO.read(Rails.root.join('all_clones_cap_ids.json')))
    dup_cap_ids.each do |cap_id|
      begin
        count += 1
        @logger.info "Processed #{count}" if count % 100 == 0

        merge cap_id
      rescue => e
        @logger.error "Problem with cap_id #{cap_id} #{e.inspect}"
        @logger.error e.backtrace.join "\n"
      end
    end

    @logger.info "Contributions fixed: #{@contribs_fixed}"
    @logger.info "Clones removed: #{@clones_removed}"
  rescue => e
    @logger.error e.inspect.to_s
    @logger.error e.backtrace.join "\n"
  end
end

c = MergeDuplicateAuths.new
c.work
