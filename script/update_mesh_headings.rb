# frozen_string_literal: true

class UpdateMeshHeadings
  def initialize
    @logger = Logger.new(Rails.root.join('log/update_mesh_headings.log'))
    @logger.formatter = proc { |severity, datetime, _progname, msg|
      "#{severity} #{datetime}: #{msg}\n"
    }
    @pmids = PubmedSourceRecord.pluck(:pmid)
    @logger.info "Processing #{@pmids.count} pmids"
    @updated = 0
    @skipped = 0
    @errors = 0
    @psr = PubmedSourceRecord.new
  end

  def update
    count = 0
    @pmids.each do |pmid|
      count += 1
      process pmid
      @logger.info "Processed #{count}" if count % 500 == 0
    rescue StandardError => e
      @errors += 1
      @logger.error "Unable to process #{pmid}: #{e.inspect}"
      @logger.error e.backtrace.join("\n")
    end

    @logger.info "Updated #{@updated}"
    @logger.info "Skipped #{@skipped}"
    @logger.info "Errors  #{@errors}"
  end

  def process(pmid)
    pm_xml = Pubmed::Client.new.fetch_records_for_pmid_list pmid
    doc = Nokogiri::XML(pm_xml)
    articles = doc.xpath('//PubmedArticle')
    if articles.size != 1
      @logger.warn "Found #{articles.size} PubmedArticles for #{pmid}. Skipping"
      @skipped += 1
      return
    end

    pm_mesh = @psr.extract_mesh_headings_from_pubmed_record articles.first
    if pm_mesh.empty?
      @logger.warn "No mesh headings from PubMed #{pmid}. Skipping"
      @skipped += 1
      return
    end

    pubs = Publication.where pmid: pmid
    if pubs.size != 1
      @logger.warn "Found #{pubs.size} Publications for #{pmid}. Skipping"
      @skipped += 1
      return
    end

    pub = pubs.first
    pub_hash = pub.pub_hash
    old_mesh = pub_hash[:mesh_headings]
    if pm_mesh == old_mesh
      @skipped += 1
    else
      pub_hash[:mesh_headings] = pm_mesh
      pub.pub_hash = pub_hash
      pub.sync_publication_hash_and_db
      pub.save
      @logger.info "Updated mesh for pub: #{pub.id} pmid: #{pmid}"
      @updated += 1
    end
  end
end

u = UpdateMeshHeadings.new
u.update
