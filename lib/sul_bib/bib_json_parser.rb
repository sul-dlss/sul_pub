module SulBib
  class BibJSONParser
    def self.call(object, _env)
      { pub_hash: JSON.parse(object) }
    end
  end
end
