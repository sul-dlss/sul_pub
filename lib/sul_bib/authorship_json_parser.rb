module SulBib
  class AuthorshipJSONParser
    delegate :has_key?, :[], to: :hash

    attr_reader :hash

    def self.call(object, _env)
      parser = AuthorshipJSONParser.from_json object

      parser.to_h
    end

    def self.from_json(json_blob)
      AuthorshipJSONParser.new JSON.parse(json_blob)
    end

    def initialize(pub_hash)
      @hash = pub_hash.with_indifferent_access
    end

    def author_hash
      h = {}

      h[:id] = self[:sul_author_id]
      h[:cap_profile_id] = self[:cap_profile_id]

      h.reject { |_k, v| v.blank? }
    end

    def publication_hash
      h = {}
      h[:id] = self[:sul_pub_id]
      h[:pmid] = self[:pmid]
      h[:sciencewire_id] = self[:sw_id]

      h.reject { |_k, v| v.blank? }
    end

    def to_h
      h = @hash.dup
      h.merge!(author: author_hash) unless author_hash.empty?
      h.merge!(publication: publication_hash) unless publication_hash.empty?
      h
    end
  end
end
