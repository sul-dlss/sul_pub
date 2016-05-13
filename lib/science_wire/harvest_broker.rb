module ScienceWire
  ##
  # Brokers queries for an author
  class HarvestBroker
    attr_reader :author, :sciencewire_harvester, :seed_list, :alternate_name_query
    delegate :use_middle_name, :sciencewire_client, to: :sciencewire_harvester

    ##
    # @param [Author] author
    # @param [ScienceWireHarvester] sciencewire_harvester
    # @param [Boolean] alternate_name_query
    def initialize(author, sciencewire_harvester, alternate_name_query: false)
      @author = author
      @sciencewire_harvester = sciencewire_harvester
      @alternate_name_query = alternate_name_query
    end

    ##
    # Returns a new set of ScienceWire PublicationIds to be harvested
    # @return [Array<Integer>]
    def generate_ids
      (ids_for_author | ids_for_alternate_names) - author_pub_swids
    end

    ##
    # The traditional Author only harvest approach
    # @return [Array<Integer>]
    def ids_for_author
      name = author_name(author)
      institution = sciencewire_harvester.default_institution
      if seed_list.size < 50
        sciencewire_harvester.increment_authors_with_limited_seed_data_count
        author_attributes = AuthorAttributes.new(name, '', [], institution)
        ids_from_dumb_query(author_attributes)
      else
        author_attributes = AuthorAttributes.new(name, author.email, seed_list, institution)
        ids_from_smart_query(author_attributes)
      end
    end

    ##
    # Generates alternate name ids using the "dumb" query
    # @return [Array<Integer>]
    def ids_for_alternate_names
      if alternate_name_query
        author.alternative_identities.select{|author_identity| required_data_for_alt_names_search(author_identity)}.map do |author_identity|
          ids_from_dumb_query(author_identity).flatten
        end.flatten.uniq
      else
        []
      end
    end

    ##
    # @param [AuthorAttributes] author_attributes
    # @return [Array<Integer>]
    def ids_from_dumb_query(author_attributes)
      sciencewire_client.query_sciencewire_by_author_name(author_attributes)
    end

    ##
    # @param [AuthorAttributes] author_attributes
    # @return [Array<Integer>]
    def ids_from_smart_query(author_attributes)
      sciencewire_client.get_sciencewire_id_suggestions(author_attributes)
    end

    private

      ##
      # Accessors for custom Author information. Eventually could migrate to
      # AuthorAttributes as the client changes underneath.
      def seed_list
        @seed_list ||= author.publications.approved.with_sciencewire_id
                             .pluck(:sciencewire_id).uniq
      end

      def author_pub_swids
        @author_pub_swids ||= author.publications.with_sciencewire_id.pluck(:sciencewire_id).uniq
      end

      def author_name(person)
        AuthorName.new(
          person.last_name,
          person.first_name,
          use_middle_name ? person.middle_name : ''
        )
      end

      def author_attributes_from_author_identity(author_identity)
        name = author_name(author_identity)
        AuthorAttributes.new(
          name,
          author_identity.email,
          [],
          author_identity.institution,
          author_identity.start_date,
          author_identity.end_date
        )
      end

      def required_data_for_alt_names_search(author_identity)
        #don't search unless first name, last name, and institution are provided
        #and when the institution is NOT "all", blank, null, or *
        return true if author_identity.first_name.present? && author_identity.last_name.present? && inst_valid_for_alt_names_search(author_identity.institution)
        false
      end

      def inst_valid_for_alt_names_search(inst)
        #don't search when institution is "all", blank, null, or *
        return true if inst.present? && inst != 'all' && inst != '*'
        false
      end
  end
end
