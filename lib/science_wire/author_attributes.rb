module ScienceWire
  ##
  # Attributes used for creating author search queries
  class AuthorAttributes
    attr_reader :last_name, :first_name, :middle_name, :email, :seed_list, :institution, :start_date, :end_date

    # FIXME: remove this rubocop:disable with a refactor
    # rubocop:disable Metrics/ParameterLists
    def initialize(last_name, first_name, middle_name, email, seed_list, institution = '', start_date = nil, end_date = nil)
      @last_name = last_name.to_s
      @first_name = first_name.to_s
      @middle_name = middle_name.to_s
      @email = email.to_s
      @seed_list = seed_list
      @institution = normalize_institution(institution.to_s)
      @start_date = start_date
      @end_date = end_date
    end
    # rubocop:enable Metrics/ParameterLists

    def first_name_initial
      first_name.strip[0].to_s
    end

    # Normalize the institution by removing some common name elements that do
    # nothing to distinguish the institution.
    def normalize_institution(institution)
      institution.gsub!(/university/i, '')
      institution.gsub!(/institute/i, '')
      institution.gsub!(/organization/i, '')
      institution.gsub!(/corporation/i, '')
      institution.gsub!(/and/i, '')
      institution.gsub!(/the/i, '')
      institution.gsub!(/of/i, '')
      # TODO: what to do with 'all' or '*'?
      institution.gsub!(/\s+/, ' ')
      institution.strip!
      institution.downcase # it's not case sensitive
    end
  end
end
