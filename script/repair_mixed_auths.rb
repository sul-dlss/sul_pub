# frozen_string_literal: true

require 'csv'

class RepairMixedAuths
  def initialize
    @logger = Logger.new(Rails.root.join('log', 'repair_mixed_auths.log'))
    @auths_fixed = 0
    @contribs_fixed = 0
  end

  # rubocop:disable Style/CombinableLoops
  def fix(row)
    return if row[:cap_profile_id] == row[:sul_profile_id]

    @logger.info "Replacing sul_profile_id #{row[:sul_profile_id]} with cap_profile_id #{row[:cap_profile_id]}"
    auth = Author.find row[:sul_author_id]
    @auths_fixed += 1
    contribs = auth.contributions

    auth.cap_profile_id = row[:cap_profile_id]
    auth.save
    contribs.each do |contrib|
      contrib.cap_profile_id = row[:cap_profile_id]
      contrib.save
    end

    contribs.each do |contrib|
      pub = contrib.publication
      pub.sync_publication_hash_and_db
      pub.save
      @logger.info "   Synching pub #{pub.id}"
      @contribs_fixed += 1
    end
    # rubocop:enable Style/CombinableLoops
  rescue ActiveRecord::RecordNotFound
    @logger.warn "Author id not found #{auth_id}"
  end

  def work
    ActiveRecord::Base.logger.level = 1
    count = 0
    CSV.foreach(Rails.root.join('authors_with_profiles_utf8.csv'), headers: true, header_converters: :symbol) do |row|
      begin
        count += 1
        @logger.info "Processed #{count}" if count % 100 == 0

        fix row
      rescue StandardError => e
        @logger.error "Problem author #{row[:sul_author_id]} #{e.inspect}"
        @logger.error e.backtrace.join "\n"
      end
    end

    @logger.info "Authors fixed: #{@auths_fixed}"
    @logger.info "Contributions fixed: #{@contribs_fixed}"
  rescue StandardError => e
    @logger.error e.inspect.to_s
    @logger.error e.backtrace.join "\n"
  end
end

c = RepairMixedAuths.new
c.work
