require 'csv'

class DeleteMissingAuths

  def initialize
    @logger = Logger.new(Rails.root.join('log', "delete_missing_auths.log"))
  end


  def fix(auth_id)
    auth = Author.find auth_id
    pubs = auth.publications

    orphan_pubs = pubs.select {|p| p.contributions.size == 1}
    orphan_pubs.each do |p|
      @logger.info "   Destroying orphan pub #{p.id}"
      p.destroy
    end

    @logger.info "Destroying author #{auth.id}"
    auth.destroy
  rescue ActiveRecord::RecordNotFound => e
    @logger.warn "Author id not found #{auth_id}"
  end

  def work
    ActiveRecord::Base.logger.level = 1
    count = 0
    CSV.foreach(Rails.root.join('authors_without_profiles_utf8.csv'), :headers  => true, :header_converters => :symbol) do |row|
      begin
        count += 1
        @logger.info "Processed #{count}" if(count % 100 == 0)

        fix row[:sul_author_id]
      rescue => e
        @logger.error "Problem author #{row[:sul_author_id]} #{e.inspect}"
        @logger.error e.backtrace.join "\n"
      end
    end

    rescue => e
      @logger.error "#{e.inspect}"
      @logger.error e.backtrace.join "\n"
  end
end

c = DeleteMissingAuths.new
c.work
