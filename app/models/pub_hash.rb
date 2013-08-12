require 'citeproc'

class PubHash
  def initialize hash
    @hash = hash
  end

  def pub_hash
    @hash
  end

  def to_chicago_citation
    chicago_csl_file = Rails.root.join('app', 'data', 'chicago-author-date.csl')
    CiteProc.process(to_citation_data, :style => chicago_csl_file, :format => 'html')
  end

  def to_mla_citation
    mla_csl_file = Rails.root.join('app', 'data', 'mla.csl')
    CiteProc.process(to_citation_data, :style => mla_csl_file, :format => 'html')
  end

  def to_apa_citation
    apa_csl_file = Rails.root.join('app', 'data', 'apa.csl')
    CiteProc.process(to_citation_data, :style => apa_csl_file, :format => 'html')
  end

  def to_citation_data
    @citation_data ||= begin
      authors_for_citeproc = []

      authors = pub_hash[:author] || []

      if authors.length > 5
        authors = authors[0..4]
        authors << {:name=>"et al."}
      elsif pub_hash[:etal]
        authors = pub_hash[:author].dup
        authors << {:name=>"et al."}
      end

      authors.each do |author|
        last_name = ""
        rest_of_name = ""

        # use parsed name parts if available
        unless author[:lastname].blank?
          last_name = author[:lastname]
          unless author[:firstname].blank?
            if author[:firstname].length == 1
              rest_of_name << ' ' << author[:firstname] << '.'
            else
              rest_of_name << ' ' <<  author[:firstname]
            end
          end

          unless author[:middlename].blank?
            if author[:middlename].length == 1
              rest_of_name << ' ' << author[:middlename] << '.'
            else
              rest_of_name << ' ' <<  author[:middlename]
            end
          end
        end

        # use name otherwise and if available
        if last_name.blank? && ! author[:name].blank?
          author[:name].split(',').each_with_index do |name_part, index|
            if index == 0
              last_name = name_part
            elsif name_part.length == 1
              # the name part is only one character so an initial
              rest_of_name << ' ' << name_part << '.'
            elsif name_part.length > 1
              rest_of_name << ' ' << name_part
            end
          end
        end

        unless last_name.blank?
          authors_for_citeproc << {"family" => last_name, "given" => rest_of_name}
        end
      end


      cit_data_hash = {"id" => "sulpub",
                   "type"=>pub_hash[:type],
                   "author"=>authors_for_citeproc,
                   "title"=>pub_hash[:title]

                   }

      cit_data_hash["abstract"] = pub_hash[:abstract] unless pub_hash[:abstract].blank?

      # add series information if it exists
      if pub_hash.has_key?(:series)
        cit_data_hash["container-title"] = pub_hash[:series][:title] unless pub_hash[:series][:title].blank?
        cit_data_hash["volume"] = pub_hash[:series][:volume] unless pub_hash[:series][:volume].blank?
        cit_data_hash["issue"] = pub_hash[:series][:number] unless pub_hash[:series][:number].blank?
        cit_data_hash["issued"]  = {"date-parts"=>[[pub_hash[:series][:year]]]} unless pub_hash[:series][:year].blank?
     end
     # add journal information if it exists
     if pub_hash.has_key?(:journal)
        cit_data_hash["container-title"] = pub_hash[:journal][:name] unless pub_hash[:journal][:name].blank?
        cit_data_hash["volume"] = pub_hash[:journal][:volume] unless pub_hash[:journal][:volume].blank?
        cit_data_hash["issue"] = pub_hash[:journal][:issue] unless pub_hash[:journal][:issue].blank?
        cit_data_hash["issued"]  = {"date-parts"=>[[pub_hash[:journal][:year]]]} unless pub_hash[:journal][:year].blank?
      end
      # use a year at the top level if it exists, i.e, override any year we'd gotten above from journal or series
      cit_data_hash["issued"]  = {"date-parts"=>[[pub_hash[:year]]]} unless pub_hash[:year].blank?
      # add book title if it exists, which indicates this pub is a chapter in the book
      cit_data_hash["container-title"] = pub_hash[:booktitle] unless pub_hash[:booktitle].blank?


      cit_data_array = [cit_data_hash]
    end
  end
end