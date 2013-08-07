class Publication < ActiveRecord::Base

  before_save do
    sync_publication_hash_and_db if pubhash_needs_update
  end

  # colums we actually use and query on
  attr_accessible :deleted,
                  :pub_hash,
                  :pmid,
                  :sciencewire_id,
                  :updated_at

  # beats me what these are for.
  attr_accessible :active, :lock_version                  

  # we actually do query these columns in 
  # create_or_update_pub_and_contribution_with_harvested_sw_doc
  attr_reader :title,
              :year, 
              :issn, 
              :pages, 
              :publication_type                
  
  before_save do
    self.title = pub_hash[:title] unless pub_hash[:title].blank?
    self.issn = pub_hash[:issn] unless pub_hash[:issn].blank?
    self.pages = pub_hash[:pages] unless pub_hash[:pages].blank?
    self.publication_type = pub_hash[:type] unless pub_hash[:type].blank?
    self.year = pub_hash[:year] unless pub_hash[:year].blank?
  end

  def title
    self.pub_hash[:title]
  end

  def issn
    self.pub_hash[:issn]
  end

  def pages
    self.pub_hash[:pages]
  end

  def publication_type
    self.pub_hash[:type]
  end

  def year
    self.pub_hash[:year]
  end

  has_many :contributions, :dependent => :destroy, :after_add => :pubhash_needs_update!, :after_remove => :pubhash_needs_update!
  has_many :authors, :through => :contributions, :after_add => :pubhash_needs_update!, :after_remove => :pubhash_needs_update!
  has_many :publication_identifiers, :dependent => :destroy
  has_many :user_submitted_source_records
  has_one :batch_uploaded_source_record
  #has_many :population_membership, :foreign_key => "author_id"
  #validates_uniqueness_of :pmid
  #validates_uniqueness_of :sciencewire_id

  serialize :pub_hash, Hash

  def self.updated_after date
    where('publications.updated_at > ?', date)
  end

  def self.with_active_author
    Publication.where(:id => joins(:authors).where('authors.active_in_cap' => true).select('publications.id').uniq.pluck(:id))
  end

  def self.find_or_create_by_pmid(pmid)
    Publication.where(pmid: pmid).first || SciencewireSourceRecord.get_pub_by_pmid(pmid) || PubmedSourceRecord.get_pub_by_pmid(pmid)
  end

  def self.find_or_create_by_sciencewire_id(sw_id)
    pub = Publication.where(sciencewire_id: sw_id).first || SciencewireSourceRecord.get_pub_by_sciencewire_id(sw_id)
  end

  def self.build_new_manual_publication(provenance, pub_hash, original_source_string)

    fingerprint = Digest::SHA2.hexdigest(original_source_string)
    existingRecord = UserSubmittedSourceRecord.where(source_fingerprint: fingerprint).first

    if existingRecord
      pub = existingRecord.publication
      unless pub.nil?
        pub.update_manual_pub_from_pub_hash(pub_hash, provenance, original_source_string)
      else
        pub = initialize_from_man_pub(pub_hash, provenance)
        pub.sync_publication_hash_and_db
      end
    else
      pub = initialize_from_man_pub(pub_hash, provenance)
      pub.save
      # todo:  have to look at deleting old identifiers, old contribution info, from db  i.e, how to correct errors.
      pub.user_submitted_source_records.create(
        is_active: true,
        :source_fingerprint => Digest::SHA2.hexdigest(original_source_string),
        :source_data => original_source_string
      )
      pub.update_any_new_contribution_info_in_pub_hash_to_db
      pub.sync_publication_hash_and_db
    end
    
    pub.save
    pub
  end

  def self.initialize_from_man_pub(pub_hash, provenance)
    pub_hash[:provenance] = provenance
    Publication.new(
          active: true,
          pub_hash: pub_hash
         )
  end

  def build_from_sciencewire_hash(new_sw_pub_hash)
    self.pub_hash = new_sw_pub_hash

    self.sciencewire_id = new_sw_pub_hash[:sw_id]
 
    unless self.pmid.blank?
      new_sw_pub_hash[:pmid] = self.pmid.to_s # Preserve the pmid just in case incoming sciencewire doc doesn't have PMID
      add_any_pubmed_data_to_hash
    end

    self
  end

  def build_from_pubmed_hash(new_pubmed_pub_hash)
    self.pub_hash = new_pubmed_pub_hash
    self
  end

  def update_manual_pub_from_pub_hash(incoming_pub_hash, provenance, original_source_string)

    incoming_pub_hash[:provenance] = provenance
    self.pub_hash = incoming_pub_hash

    self.user_submitted_source_records.first.update_attributes(
        is_active: true,
        :source_fingerprint => Digest::SHA2.hexdigest(original_source_string),
        :source_data => original_source_string
    )

    self.update_any_new_contribution_info_in_pub_hash_to_db
    self.sync_publication_hash_and_db
    self.save
  end

  def add_any_pubmed_data_to_hash
    return if self.pmid.blank?
    pubmed_hash = PubmedSourceRecord.get_pubmed_hash_for_pmid(self.pmid)
    return if pubmed_hash.nil?

    self.pub_hash[:mesh_headings] = pubmed_hash[:mesh_headings] unless pubmed_hash[:mesh_headings].blank?
    self.pub_hash[:abstract] = pubmed_hash[:abstract] unless pubmed_hash[:abstract].blank?
  end

  def set_last_updated_value_in_hash
    self.pub_hash[:last_updated] = (updated_at || Time.now).to_s
  end

  def set_sul_pub_id_in_hash
    sul_pub_id = self.id.to_s
    self.pub_hash[:sulpubid] = sul_pub_id
    self.pub_hash[:identifier] ||= []
    self.pub_hash[:identifier] << {:type => 'SULPubId', :id => sul_pub_id, :url => 'http://sulcap.stanford.edu/publications/' + sul_pub_id}
  end

  # this is a very temporary method to be used only for the initial import
  # of data from CAP.
  def cutover_sync_hash_and_db
    set_sul_pub_id_in_hash
    self.pub_hash[:last_updated] = self.updated_at.to_s
    add_all_db_contributions_to_my_pub_hash
    #add identifiers that are in the hash to the pub identifiers db table
    self.pub_hash[:identifier].each do |identifier|
          self.publication_identifiers.create(
            :identifier_type => identifier[:type],
            :certainty => 'confirmed',
            :identifier_value => identifier[:id],
            :identifier_uri => identifier[:url])
    end
    update_formatted_citations
    save
  end

  def sync_publication_hash_and_db
    set_last_updated_value_in_hash
    set_sul_pub_id_in_hash

    add_all_db_contributions_to_my_pub_hash
    add_any_new_identifiers_in_pub_hash_to_db
    add_all_identifiers_in_db_to_pub_hash

    update_formatted_citations
    @pubhash_needs_update = false
    true
  end

  def rebuild_pub_hash
    if self.sciencewire_id
      sw_source_record = SciencewireSourceRecord.where(sciencewire_id: self.sciencewire_id).first
      build_from_sciencewire_hash(sw_source_record.get_source_as_hash)
    elsif self.pmid
      pubmed_source_record = PubmedSourceRecord.where(pmid: self.pmid).first
      build_from_pubmed_hash(pubmed_source_record.get_source_as_hash)
    end
    #otherwise, probably manual or batch loaded, so just rebuild identifiers, contributions, and citations from db
    # and update the issn, pages, and pub type
      issn = self.pub_hash[:issn]
      pages = self.pub_hash[:pages]
      publication_type = self.pub_hash[:type]
      self.update_attributes(issn: issn, pages: pages, publication_type: publication_type)

      set_last_updated_value_in_hash
      add_all_db_contributions_to_my_pub_hash
      add_all_identifiers_in_db_to_pub_hash
      update_formatted_citations
  end

  def rebuild_authorship
    add_all_db_contributions_to_my_pub_hash
  end

  def add_any_new_identifiers_in_pub_hash_to_db
    Array(self.pub_hash[:identifier]).each do |identifier|
      self.publication_identifiers
          .where(:identifier_type => identifier[:type])
          .first_or_create(:certainty => 'confirmed',
                           :identifier_value => identifier[:id],
                           :identifier_uri => identifier[:url])
    end
  end

  def add_all_identifiers_in_db_to_pub_hash
    self.pub_hash[:identifier] = self.publication_identifiers.collect do |identifier|
      ident_hash = Hash.new
      ident_hash[:type] = identifier.identifier_type unless identifier.identifier_type.blank?
      ident_hash[:id] = identifier.identifier_value unless identifier.identifier_value.blank?
      ident_hash[:url] = identifier.identifier_uri unless identifier.identifier_uri.blank?
      ident_hash
    end
  end


  def update_any_new_contribution_info_in_pub_hash_to_db
    Array(self.pub_hash[:authorship]).each do |contrib|
      hash_for_update = {
        status: contrib[:status],
        visibility: contrib[:visibility],
        featured: contrib[:featured]
      }
    
      sul_author_id = contrib[:sul_author_id]
      
      author = if sul_author_id
        Author.find(sul_author_id)
      elsif contrib[:cap_profile_id]
        Author.where(cap_profile_id: contrib[:cap_profile_id]).first
      else
      end
      
      # todo??
      next if author.nil? 

      cap_profile_id = author.cap_profile_id
      hash_for_update[:cap_profile_id] = cap_profile_id unless cap_profile_id.blank?
      
      contrib = self.contributions.where(:author_id => author.id).first_or_create
      contrib.update_attributes(hash_for_update)
    end
  end

  def add_all_db_contributions_to_my_pub_hash

    if self.pub_hash
      self.pub_hash[:authorship] = contributions.map { |x| x.to_pub_hash }
    end
   # elsif self.pub_hash && ! self.pub_hash[:authorship]
    #  Logger.new(Rails.root.join('log', 'publications_errors.log')).info("No authorship entry in pub_hash for " + self.id.to_s)
    #else
    #  Logger.new(Rails.root.join('log', 'publications_errors.log')).info("No pub hash for " + self.id.to_s)
    #end
  rescue => e
    puts "some problem with hash: #{self.pub_hash}"
    pub_logger = Logger.new(Rails.root.join('log', 'contributions_publications_errors.log'))
    pub_logger.error "some problem with adding contributions to the hash for pub #{self.id}"
    pub_logger.error "the hash: #{self.pub_hash}"
    pub_logger.error e.message
    pub_logger.error e.backtrace
  end

  def update_formatted_citations
    #[{"id"=>"Gettys90", "type"=>"article-journal", "author"=>[{"family"=>"Gettys", "given"=>"Jim"}, {"family"=>"Karlton", "given"=>"Phil"}, {"family"=>"McGregor", "given"=>"Scott"}], "title"=>"The {X} Window System, Version 11", "container-title"=>"Software Practice and Experience", "volume"=>"20", "issue"=>"S2", "abstract"=>"A technical overview of the X11 functionality.  This is an update of the X10 TOG paper by Scheifler \\& Gettys.", "issued"=>{"date-parts"=>[[1990]]}}]
    h = PubHash.new(pub_hash)

    pub_hash[:apa_citation] = h.to_apa_citation
    pub_hash[:mla_citation] = h.to_mla_citation
    pub_hash[:chicago_citation] = h.to_chicago_citation
  end

  def delete!
    deleted = true
    save
  end

  def deleted?
    deleted
  end

  def add_or_update_author author, contribution_hash = {}
    if contributions.exists? :author_id => author.id
      c = contributions.where(:author_id => author.id).first
      c.update_attributes contribution_hash
      pubhash_needs_update!
    else
      c = contributions.create(contribution_hash.merge(:author_id => author.id))
    end

    c
  end

  def pubhash_needs_update! *args
    @pubhash_needs_update = true
  end

  def pubhash_needs_update
    @pubhash_needs_update || false
  end

end



