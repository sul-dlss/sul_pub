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
      name = AuthorName.new(author_last_name, author_first_name, author_middle_name)
      if seed_list.size < 50
        sciencewire_harvester.increment_authors_with_limited_seed_data_count
        ids_from_dumb_query(name)
      else
        ids_from_smart_query(name, author.email, seed_list)
      end
    end

    ##
    # Generates alternate name ids using the "dumb" query
    # @return [Array<Integer>]
    def ids_for_alternate_names
      if alternate_name_query
        author.alternative_identities.map do |author_identity|
          name = AuthorName.new(
            author_identity.last_name,
            author_identity.first_name,
            use_middle_name ? author_identity.middle_name : ''
          )
          ids_from_dumb_query(name).flatten
        end.flatten.uniq
      else
        []
      end
    end

    ##
    # @param [AuthorName] name
    # @return [Array<Integer>]
    def ids_from_dumb_query(name)
      sciencewire_client.query_sciencewire_by_author_name(name)
    end

    ##
    # @param [AuthorName] name
    # @param [String] email
    # @param [Array] seed_list
    # @return [Array<Integer>]
    def ids_from_smart_query(name, email, seed_list)
      sciencewire_client.get_sciencewire_id_suggestions(name, email, seed_list)
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

      def author_first_name
        author.preferred_first_name
      end

      def author_middle_name
        use_middle_name ? author.preferred_middle_name : ''
      end

      def author_last_name
        author.preferred_last_name
      end
  end
end
