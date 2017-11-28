require 'csv'

class DeleteMissingAuths
  def initialize
    @logger = Logger.new(Rails.root.join('log', 'delete_missing_auths.log'))
  end

  def fix(auth_id)
    auth = Author.find auth_id
    pub_ids = auth.publications.pluck(:id)

    @logger.info "Destroying author #{auth.id}"
    auth.destroy
    pub_ids.each do |pub_id|
      pub = Publication.find pub_id
      if pub.contributions.empty?
        @logger.info "   Destroying orphan pub #{pub_id}"
        pub.destroy
      else
        @logger.info "   Resynching pub #{pub_id}"
        pub.set_last_updated_value_in_hash
        pub.add_all_db_contributions_to_my_pub_hash
        pub.save
      end
    end
  rescue ActiveRecord::RecordNotFound
    @logger.warn "Author id not found #{auth_id}"
  end

  def work
    ActiveRecord::Base.logger.level = 1
    count = 0
    CSV.foreach(Rails.root.join('authors_without_profiles_utf8.csv'), headers: true, header_converters: :symbol) do |row|
      begin
        count += 1
        @logger.info "Processed #{count}" if count % 100 == 0
        fix row[:sul_author_id]
      rescue => e
        @logger.error "Problem author #{row[:sul_author_id]} #{e.inspect}"
        @logger.error e.backtrace.join "\n"
      end
    end
  rescue => e
    @logger.error e.inspect.to_s
    @logger.error e.backtrace.join "\n"
  end
end

c = DeleteMissingAuths.new
c.work
