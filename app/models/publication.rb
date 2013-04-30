class Publication < ActiveRecord::Base
  attr_accessible :active, :deleted, :title, :year, :pub_hash, :lock_version, :same_as_publication_id, :xml, :updated_at
  has_many :contributions, :dependent => :destroy
  has_many :authors, :through => :contributions
  has_many :publication_identifiers, :dependent => :destroy
  has_many :source_records
  has_many :population_membership, :foreign_key => "author_id"
  
  serialize :pub_hash, Hash
  
  def self.build_new_sciencewire_publication(pub_hash, sw_xml_doc, mesh_for_pub, author, contrib_status)

      is_active = true

      pub = Publication.create(active: is_active, title: pub_hash[:title], pub_hash: pub_hash, year: pub_hash[:year])

      pub.update_mesh(mesh_for_pub)
      pub.add_contribution_to_db(author.id, author.cap_profile_id, contrib_status)
      
      sciencewire_source_id = pub_hash[:sw_id]
      pub.save_source_record(sw_xml_doc.to_xml, Settings.sciencewire_source, sciencewire_source_id, is_active)    
      
      pub.sync_publication_hash_and_db
      pub
  end

def self.build_new_manual_publication(provenance, pub_hash)

    is_active = true
    pub_hash[:provenance] = provenance

    pub = Publication.create(active: is_active, title: pub_hash[:title], year: pub_hash[:year], pub_hash: pub_hash)
    
    # todo:  have to look at deleting old identifiers, old contribution info.
    original_source_id = nil
    pub.save_source_record(pub_hash.to_s, Settings.manual_source, original_source_id, is_active)
    pub.sync_publication_hash_and_db
    pub
  end

def update_manual_pub_from_pub_hash(incoming_pub_hash, provenance)
    
    is_active = true
    incoming_pub_hash[:provenance] = provenance
    self.title = incoming_pub_hash[:title]
    self.year = incoming_pub_hash[:year]
    self.pub_hash = incoming_pub_hash
    original_source_id = nil

    save_source_record(incoming_pub_hash.to_s, Settings.manual_source, original_source_id, is_active)
    
    sync_publication_hash_and_db
    
end

def save_source_record(data_to_save, source_name, source_record_id, is_active)
    if source_name == Settings.manual_source
        is_local_only = ! source_records.exists?(:is_local_only => false)
    else
        is_local_only = false
    end
    source_record = source_records.where(:original_source_id => source_record_id, :source_name => source_name).
    first_or_create(
      :title => title, :year => year, :is_local_only => is_local_only, :is_active => is_active
    )
    source_record.source_data = data_to_save
    source_record.save
  end


def add_contribution(cap_profile_id, sul_author_id, contrib_status)
      self.pub_hash[:contributions] = [ {:cap_profile_id => cap_profile_id, :sul_author_id => sul_author_id, :status => contrib_status}]
      sync_publication_hash_and_db
end

def update_mesh(mesh_for_pub)
      pmid = self.pub_hash[:pmid]
      if mesh_for_pub.nil? && ! pmid.nil?
        self.pub_hash[:mesh_headings] = get_mesh_from_pubmed([pmid])[pmid]
      else
        self.pub_hash[:mesh_headings] = mesh_for_pub
      end
end

def set_last_updated_value_in_hash
  save   # to reset last updated value
  self.pub_hash[:last_updated] = updated_at
    
end

def set_sul_pub_id_in_hash
  sul_pub_id = id.to_s           
  self.pub_hash[:sulpubid] = sul_pub_id
  self.pub_hash[:identifier] ||= []
  self.pub_hash[:identifier] << {:type => 'SULPubId', :id => sul_pub_id, :url => 'http://sulcap.stanford.edu/publications/' + sul_pub_id}            
end

def sync_publication_hash_and_db

    set_sul_pub_id_in_hash
    set_last_updated_value_in_hash
    
    sync_contributions
    sync_identifers
    
    update_formatted_citations
    update_canonical_xml_for_pub
    
    save
  end

def update_formatted_citations
    #[{"id"=>"Gettys90", "type"=>"article-journal", "author"=>[{"family"=>"Gettys", "given"=>"Jim"}, {"family"=>"Karlton", "given"=>"Phil"}, {"family"=>"McGregor", "given"=>"Scott"}], "title"=>"The {X} Window System, Version 11", "container-title"=>"Software Practice and Experience", "volume"=>"20", "issue"=>"S2", "abstract"=>"A technical overview of the X11 functionality.  This is an update of the X10 TOG paper by Scheifler \\& Gettys.", "issued"=>{"date-parts"=>[[1990]]}}]
    chicago_csl_file = Rails.root.join('app', 'data', 'chicago-author-date.csl')
    authors_for_citeproc = []
    authors = pub_hash[:author]
    if authors.length > 5 
      authors = authors[1..4]
      authors << {:name=>"et al."}
    end
    authors.each do |author|
      last_name = ""
      rest_of_name = ""
      author[:name].split(',').each_with_index do |name_part, index|
        if index == 0
          last_name = name_part
        elsif name_part.length == 1
          rest_of_name << ' ' << name_part << '.'
        elsif name_part.length > 1
          rest_of_name << ' ' << name_part
        end
      end
      authors_for_citeproc << {"family" => last_name, "given" => rest_of_name}
    end

    
    cit_data_hash = {"id" => "test89",
                 "type"=>pub_hash[:type],
                 "author"=>authors_for_citeproc,
                 "title"=>pub_hash[:title],
                 "issued"=>{"date-parts"=>[[pub_hash[:year]]]}
                 }
    cit_data_hash["abstract"] = pub_hash[:abstract] unless pub_hash[:abstract].blank?
    if pub_hash.has_key?(:journal)
            cit_data_hash["container-title"] = pub_hash[:journal][:name] unless pub_hash[:journal][:name].blank?
            cit_data_hash["volume"] = pub_hash[:journal][:volume] unless pub_hash[:journal][:volume].blank?
            cit_data_hash["issue"] = pub_hash[:journal][:issue] unless pub_hash[:journal][:issue].blank?             
    end     
    cit_data_array = [cit_data_hash]         

    # chicago_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/chicago-author-date.csl', :format => 'html')
    # apa_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/apa.csl', :format => 'html')
    # mla_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/mla.csl', :format => 'html')
    pub_hash[:apa_citation] = CiteProc.process(cit_data_array, :style => :apa, :format => 'html')
    pub_hash[:mla_citation] = CiteProc.process(cit_data_array, :style => :mla, :format => 'html')
    pub_hash[:chicago_citation] = CiteProc.process(cit_data_array, :style => chicago_csl_file, :format => 'html')
    
  end

   def update_canonical_xml_for_pub
=begin
    xmlbuilder = Nokogiri::XML::Builder.new do |newPubDoc|

      newPubDoc.publication {

        newPubDoc.title pub_hash[:title]
        pub_hash[:author].each do | author_name |
          newPubDoc.author {
            newPubDoc.name author_name[:name]
          }
        end
        newPubDoc.abstract_ pub_hash[:the_abstract] unless pub_hash[:the_abstract].blank?
        unless pub_hash[:keywords].blank? do
          pub_hash[:keywords].each do | keyword |
            newPubDoc.keyword keyword
          end
        end
        unless pub_hash[:documentTypes].blank? do
          pub_hash[:documentTypes].each do | docType |
            newPubDoc.type docType
          end
        end
        newPubDoc.category pub_hash[:documentCategory] unless pub_hash[:documentCategory].blank?
        newPubDoc.journal {
          newPubDoc.title pub_hash[:publicationTitle] unless pub_hash[:publicationTitle].blank?
        }

        # also add the last_update_at_source, last_retrieved_from_source,
      }


    end
    xmlbuilder.to_xml
=end
    xml = "the xml goes here"

  end

  

def sync_identifers
    add_any_new_identifiers_to_db
    add_all_known_identifiers_to_pub_hash
end

  def add_any_new_identifiers_to_db
    if pub_hash[:identifier] 
      pub_hash[:identifier].each do |identifier|
        publication_identifiers.where(
          :identifier_type => identifier[:type],
          :identifier_value => identifier[:id]).
          first_or_create(:certainty => 'confirmed', :identifier_uri => identifier[:url])
      end
    end
  end

def add_all_known_identifiers_to_pub_hash
    identifiers = Array.new
    publication_identifiers.each do |identifier|
      ident_hash = Hash.new
      ident_hash[:type] = identifier.identifier_type unless identifier.identifier_type.nil?
      ident_hash[:id] = identifier.identifier_value unless identifier.identifier_value.nil?
      ident_hash[:url] = identifier.identifier_uri unless identifier.identifier_uri.nil?
        identifiers << ident_hash
    end
    pub_hash[:identifier] = identifiers
  end

def sync_contributions
    add_any_new_contribution_info_to_db
    add_all_known_contributions_to_pub_hash
end

def add_any_new_contribution_info_to_db
  unless pub_hash[:contributions].nil?
    pub_hash[:contributions].each do |contrib|
              cap_profile_id = contrib[:cap_profile_id]
              sul_author_id = contrib[:sul_author_id] || Author.where(cap_profile_id: cap_profile_id).first.id
              contrib_status = contrib[:status]
              add_contribution_to_db(sul_author_id, cap_profile_id, contrib_status)
    end
  end
end

  def add_contribution_to_db(author_id, cap_profile_id, contrib_status)
    contributions.where(:author_id => author_id).first_or_create(
      cap_profile_id: cap_profile_id,
    confirmed_status: contrib_status)
  end

  def add_all_known_contributions_to_pub_hash
    contributions = Array.new
    Contribution.where(:publication_id => id).each do |contrib_in_db|
      contributions <<
        {:cap_profile_id => contrib_in_db.cap_profile_id,
         :sul_author_id => contrib_in_db.author_id,
         :status => contrib_in_db.confirmed_status}

        end
    pub_hash[:contributions] = contributions
  end



end



