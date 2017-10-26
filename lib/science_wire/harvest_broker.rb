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

      def author_name(person)
        Agent::AuthorName.new(
          person.last_name,
          person.first_name,
          use_middle_name ? person.middle_name : ''
        )
      end

      def author_pub_swids
        @author_pub_swids ||= author.publications.where.not(sciencewire_id: nil).pluck(:sciencewire_id).uniq
      end

      # Generates alternate name ids using the "dumb" query
      # @return [Array<Integer>]
      def ids_for_alternate_names
        return [] unless alternate_name_query
        author.alternative_identities.select { |author_identity| required_data_for_alt_names_search?(author_identity) }.map do |author_identity|
          ids_from_dumb_query(author_identity.to_author_attributes).flatten
        end.flatten.uniq
      end

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

      # Institution is valid if not "all", blank, null, or *
      def inst_valid_for_alt_names_search?(inst)
        inst.present? && inst != 'all' && inst != '*'
      end

      # Don't search unless first name, last name, and (valid) institution are provided
      def required_data_for_alt_names_search?(author_identity)
        author_identity.first_name.present? && author_identity.last_name.present? && inst_valid_for_alt_names_search?(author_identity.institution)
      end

      # Accessors for custom Author information. Eventually could migrate to
      # AuthorAttributes as the client changes underneath.
      def seed_list
        @seed_list ||= author.approved_sciencewire_ids
      end
  end
end
