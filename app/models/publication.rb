class Publication < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  after_create do
    set_sul_pub_id_in_hash
    save
  end

  # we actually do query these columns in
  # create_or_update_pub_and_contribution_with_harvested_sw_doc
  # :title,
  # :year,
  # :issn,
  # :pages,
  # :publication_type

  before_save do
    sync_publication_hash_and_db if pubhash_needs_update?
    self.title = pub_hash[:title] if pub_hash[:title].present?
    self.issn = pub_hash[:issn] if pub_hash[:issn].present?
    self.pages = pub_hash[:pages] if pub_hash[:pages].present?
    self.publication_type = pub_hash[:type] if pub_hash[:type].present?
    self.year = pub_hash[:year] if pub_hash[:year].present?
  end

  has_one :batch_uploaded_source_record

  has_many :user_submitted_source_records

  has_many :publication_identifiers,
    autosave: true,
    dependent: :destroy,
    after_add: :pubhash_needs_update!,
    after_remove: :pubhash_needs_update!

  has_many :authors,
    autosave: true,
    through: :contributions,
    after_add: :pubhash_needs_update!,
    after_remove: :pubhash_needs_update!

  has_many :contributions,
    autosave: true,
    dependent: :destroy,
    after_add: :pubhash_needs_update!,
    after_remove: :pubhash_needs_update!

  serialize :pub_hash, Hash

  def self.updated_after(date)
    where('publications.updated_at > ?', date)
  end

  def self.with_active_author
    ids = joins(:authors).where('authors.active_in_cap' => true).select('publications.id').uniq.pluck(:id)
    unscoped.where(id: ids)
  end

  def self.find_or_create_by_pmid(pmid)
    find_by_pmid(pmid) || SciencewireSourceRecord.get_pub_by_pmid(pmid) || PubmedSourceRecord.get_pub_by_pmid(pmid)
  end

  def self.find_or_create_by_sciencewire_id(sw_id)
    find_by_sciencewire_id(sw_id) || SciencewireSourceRecord.get_pub_by_sciencewire_id(sw_id)
  end

  def self.find_by_doi(doi)
    Publication.includes(:publication_identifiers)
               .find_by("publication_identifiers.identifier_type": 'doi', "publication_identifiers.identifier_value": doi)
  end

  def self.find_by_pmid_pub_id(pmid)
    Publication.includes(:publication_identifiers)
               .find_by("publication_identifiers.identifier_type": 'pmid', "publication_identifiers.identifier_value": pmid)
  end

  # Publication for a WOS-UID
  # @param [String] a WOS-UID
  # @return [Publication, nil]
  def self.for_uid(uid)
    # Until the Publication model supports a `wos_uid` field, get the pub via the identifiers
    pub_ids = PublicationIdentifier.where(identifier_type: 'WosUID', identifier_value: uid)
    return if pub_ids.empty?
    pub_ids.first.publication
  end

  # @return [Publication] new object, unsaved
  def self.build_new_manual_publication(pub_hash, original_source_string, provenance = Settings.cap_provenance)
    existingRecord = UserSubmittedSourceRecord.find_or_initialize_by_source_data(original_source_string)
    if existingRecord && existingRecord.publication
      raise ActiveRecord::RecordNotUnique.new('Publication for user submitted source record already exists', nil)
    end
    Publication.new(active: true, pub_hash: pub_hash)
               .update_manual_pub_from_pub_hash(pub_hash, original_source_string, provenance)
  end

  # @return [self]
  def update_manual_pub_from_pub_hash(incoming_pub_hash, original_source_string, provenance = Settings.cap_provenance)
    incoming_pub_hash[:provenance] = provenance
    self.pub_hash = incoming_pub_hash.dup
    match = UserSubmittedSourceRecord.find_by_source_data(original_source_string)
    match.publication = self if match # we may still throw this out w/o saving
    r = user_submitted_source_records.first || match || user_submitted_source_records.build
    r.assign_attributes(
      is_active: true,
      source_data: original_source_string,
      title: title,
      year: year
    )
    self.user_submitted_source_records = [r] if match # match is the only USSR not found/built via association
    update_any_new_contribution_info_in_pub_hash_to_db
    pubhash_needs_update! if persisted?
    self
  end

  # @return [self]
  def build_from_sciencewire_hash(new_sw_pub_hash)
    self.pub_hash = new_sw_pub_hash

    self.sciencewire_id = new_sw_pub_hash[:sw_id]

    if pmid.present?
      new_sw_pub_hash[:pmid] = pmid.to_s # Preserve the pmid just in case incoming sciencewire doc doesn't have PMID
      add_any_pubmed_data_to_hash
    end

    self
  end

  # The expecation is that every time this method gets called, a save is about to happen,
  # either because it is part of before_save callbacks or because the caller does it explicitly.
  # Subparts are relieved from the burden of directly calling save themselves.
  # @return [self]
  def sync_publication_hash_and_db
    rebuild_authorship
    sync_identifiers_in_pub_hash
    set_sul_pub_id_in_hash if persisted?
    update_formatted_citations
    @pubhash_needs_update = false
    self
  end

  def update_from_pubmed
    return false if pmid.blank?
    pm_source_record = PubmedSourceRecord.find_by_pmid(pmid)
    return false unless pm_source_record
    pm_source_record.pubmed_update
    rebuild_pub_hash
  end

  def update_from_sciencewire
    return false if sciencewire_id.blank?
    sw_source = SciencewireSourceRecord.find_by_sciencewire_id(sciencewire_id)
    return false unless sw_source
    sw_source.sciencewire_update
    rebuild_pub_hash
  end

  # @return [Boolean] true if .save is successful
  def rebuild_pub_hash
    if sciencewire_id
      sw_source_record = SciencewireSourceRecord.find_by_sciencewire_id(sciencewire_id)
      build_from_sciencewire_hash(sw_source_record.source_as_hash)
    elsif pmid
      pubmed_source_record = PubmedSourceRecord.find_by_pmid(pmid)
      self.pub_hash = pubmed_source_record.source_as_hash
    end
    sync_publication_hash_and_db
    save
  end

  def delete!
    self.deleted = true
    save
  end

  def deleted?
    deleted
  end

  # @return [true]
  def pubhash_needs_update!(*_args)
    @pubhash_needs_update = true
  end

  def pubhash_needs_update?
    @pubhash_needs_update || false
  end

  ###
  # Methods for manipulating the pub_hash data to sync db state => cached pub hash
  ###

  def rebuild_authorship
    add_all_db_contributions_to_my_pub_hash
    set_last_updated_value_in_hash
  end

  def set_last_updated_value_in_hash
    pub_hash[:last_updated] = Time.zone.now.to_s
  end

  def set_sul_pub_id_in_hash
    sul_pub_id = id.to_s
    pub_hash[:sulpubid] = sul_pub_id
    pub_hash[:identifier] ||= []
    pub_hash[:identifier] << { type: 'SULPubId', id: sul_pub_id, url: "#{Settings.SULPUB_ID.PUB_URI}/#{sul_pub_id}" }
  end

  def add_all_db_contributions_to_my_pub_hash
    pub_hash[:authorship] = contributions.map(&:to_pub_hash) if pub_hash
  rescue => e
    message = "some problem with adding contributions to the hash for publications.id=#{id}: pub_hash=#{pub_hash}"
    NotificationManager.log_exception(logger, message, e)
  end

  def update_formatted_citations
    cite = Csl::Citation.new(pub_hash)
    pub_hash[:apa_citation] = cite.to_apa_citation
    pub_hash[:mla_citation] = cite.to_mla_citation
    pub_hash[:chicago_citation] = cite.to_chicago_citation
  end

  ##
  #  Pubhash accessors
  ##
  def title
    pub_hash[:title]
  end

  def issn
    pub_hash[:issn]
  end

  def pages
    pub_hash[:pages]
  end

  def publication_type
    pub_hash[:type]
  end

  def year
    pub_hash[:year]
  end

  def sciencewire_pub?
    pub_hash[:provenance].to_s.downcase.include?('sciencewire')
  end

  def pubmed_pub?
    pub_hash[:provenance].to_s.downcase.include?('pubmed')
  end

  def authoritative_pmid_source?
    pubmed_pub? || sciencewire_pub?
  end

  alias authoritative_doi_source? sciencewire_pub?

  private

    # doesn't actually write the Pub to DB, presumed to be part of before_save callback or explicit save
    def sync_identifiers_in_pub_hash
      incoming_types = Array(pub_hash[:identifier]).map { |id| id[:type] }
      publication_identifiers.each do |id|
        next if id.identifier_type =~ /^legacy_cap_pub_id$/i # Do not delete legacy_cap_pub_id
        publication_identifiers.delete(id) unless incoming_types.include?(id.identifier_type)
      end

      Array(pub_hash[:identifier]).each do |identifier|
        next if identifier[:type] =~ /^SULPubId$/i
        i = publication_identifiers.find { |x| x.identifier_type == identifier[:type] } # find includes not yet saved pub ids
        i ||= publication_identifiers.find_or_initialize_by(identifier_type: identifier[:type])
        i.certainty        = 'confirmed'
        i.identifier_value = identifier[:id]
        i.identifier_uri   = identifier[:url]
      end
      pub_hash[:identifier] = publication_identifiers.map(&:identifier)
    end

    def add_any_pubmed_data_to_hash
      return if pmid.blank?
      pubmed_record = PubmedSourceRecord.for_pmid(pmid)
      return if pubmed_record.nil?
      pubmed_hash = pubmed_record.source_as_hash
      pub_hash[:mesh_headings] = pubmed_hash[:mesh_headings] if pubmed_hash[:mesh_headings].present?
      pub_hash[:abstract] = pubmed_hash[:abstract] if pubmed_hash[:abstract].present?
      pmc_id = pubmed_hash[:identifier].detect { |id| id[:type] == 'pmc' }
      pub_hash[:identifier] << pmc_id if pmc_id
    end

    def update_any_new_contribution_info_in_pub_hash_to_db
      Array(pub_hash[:authorship]).each do |contrib|
        hash_for_update = contrib.slice(:status, :visibility, :featured).each { |_k, v| v.downcase! if v.respond_to?(:downcase!) }
        # Find or create an Author of the contribution
        cap_profile_id = contrib[:cap_profile_id]
        author = Author.find_by_id(contrib[:sul_author_id])
        if cap_profile_id.present?
          author ||= Author.find_by_cap_profile_id(cap_profile_id)
          author ||= begin
            Author.fetch_from_cap_and_create(cap_profile_id)
          rescue => e
            msg = "error retrieving CAP profile #{cap_profile_id} for contribution: #{contrib}"
            NotificationManager.log_exception(NotificationManager.cap_logger, msg, e)
            nil
          end
        end
        next if author.nil?

        hash_for_update[:author_id] = author.id
        hash_for_update[:cap_profile_id] = author.cap_profile_id if author.cap_profile_id.present?
        contrib = contributions.where(author_id: author.id).first_or_initialize
        contrib.assign_attributes(hash_for_update)
        contrib.save if contrib.changed?
      end
      true
    end
end
