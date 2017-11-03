class PublicationIdentifierNormalization

  attr_reader :logger

  def initialize
    @logger = Logger.new(Rails.root.join('log', 'publication_identifier_normalization.log'))
  end

  # Choose a parser that can handle the PublicationIdentifier.identifier_type
  # @param pub_id [PublicationIdentifier]
  # @return parser [ParseIdentifier] a kind of ParseIdentifier to handle the pub_id
  def identifier_parser(pub_id)
    case pub_id[:identifier_type]
    when /\Adoi\z/i
      ParseIdentifierDOI.new(pub_id)
    when /\Aisbn\z/i
      ParseIdentifierISBN.new(pub_id)
    when /\Apmid\z/i
      ParseIdentifierPMID.new(pub_id)
    else
      # this default parser will not normalize any data, but it can detect blank data
      ParseIdentifier.new(pub_id)
    end
  end

  # @param pub [Publication] the Publication associated with a PublicationIdentifier
  def pub_hash_update(pub)
    pub.add_all_identifiers_in_db_to_pub_hash
    pub.save!
  rescue => e
    logger.error e.inspect
  end

  # > select distinct identifier_type from publication_identifiers;
  # doi
  # isbn
  # legacy_cap_pub_id
  # pmc
  # PMID
  # PublicationItemID
  # SULPubId
  # WoSItemID
  # @param type [String] any PublicationIdentifier.identifier_type
  # @param save_changes [Boolean] save changes
  # @param delete_blanks [Boolean] delete empty identifiers
  def normalize(type, save_changes = false, delete_blanks = false)
    PublicationIdentifier.where(identifier_type: type).order(:created_at).find_each(batch_size: 200) do |pub_id|
      begin
        pub_id = identifier_parser(pub_id).update
        if pub_id.changed? && save_changes
          pub_id.save!
          pub_hash_update(pub_id.publication)
        end
      rescue ParseIdentifierTypeError => e
        # Move along, these are not the identifiers your looking for
        logger.error e.inspect
      rescue ParseIdentifierInvalidError => e
        # The identifier_value and identifier_uri are blank or invalid
        # TODO: Try to discover the identifier in a source publication?
        logger.error e.inspect
        if delete_blanks
          pub_id.destroy!
          pub_hash_update(pub_id.publication)
        end
      rescue => e
        # Luke, you don't know the POWER of the dark side!
        logger.error e.inspect
      end
    end
  end

  def log_only
    ActiveRecord::Base.logger.level = 1
    normalize('doi')
    normalize('isbn')
    normalize('pmid')
  end

  def test_doi
    ActiveRecord::Base.logger.level = 1
    normalize('doi', true, true)
  end

  def work
    ActiveRecord::Base.logger.level = 1
    save_changes = true
    delete_blanks = true
    normalize('doi', save_changes, delete_blanks)
    normalize('isbn', save_changes, delete_blanks)
    normalize('pmid', save_changes, delete_blanks)
  end
end

# ---
# Runner main
c = PublicationIdentifierNormalization.new
c.work
