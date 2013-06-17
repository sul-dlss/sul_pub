
require 'citeproc'
class Publication < ActiveRecord::Base
  attr_accessible :active, :deleted, :title, :year, :issn, :pages, :publication_type, :pub_hash, :lock_version, :pmid, :sciencewire_id, :same_as_publication_id, :xml, :updated_at
  has_many :contributions, :dependent => :destroy
  has_many :authors, :through => :contributions
  has_many :publication_identifiers, :dependent => :destroy
  has_many :user_submitted_source_records
  has_one :batch_uploaded_source
  #has_many :population_membership, :foreign_key => "author_id"
  #validates_uniqueness_of :pmid
  #validates_uniqueness_of :sciencewire_id
  
  serialize :pub_hash, Hash
   
  
def self.get_pub_by_pmid(pmid)
    Publication.where(pmid: pmid).first || SciencewireSourceRecord.get_pub_by_pmid(pmid) || PubmedSourceRecord.get_pub_by_pmid(pmid)
end

def self.get_pub_by_sciencewire_id(sw_id)
    pub = Publication.where(sciencewire_id: sw_id).first || SciencewireSourceRecord.get_pub_by_sciencewire_id(sw_id)
end

def build_from_sciencewire_hash(new_sw_pub_hash)   
      self.pub_hash = new_sw_pub_hash
      self.sciencewire_id = new_sw_pub_hash[:sw_id]
      unless new_sw_pub_hash[:issn].blank? then self.issn = new_sw_pub_hash[:issn] end
      unless new_sw_pub_hash[:title].blank? then self.issn = new_sw_pub_hash[:title] end
      unless new_sw_pub_hash[:year].blank? then self.issn = new_sw_pub_hash[:year] end
      unless new_sw_pub_hash[:pages].blank? then self.issn = new_sw_pub_hash[:pages] end
      add_any_pubmed_data_to_hash unless new_sw_pub_hash[:pmid].blank?
      self
end

def build_from_pubmed_hash(new_pubmed_pub_hash)
    self.pub_hash = new_pubmed_pub_hash
    self
end

def self.build_new_manual_publication(provenance, pub_hash, original_source_string)

    fingerprint = Digest::SHA2.hexdigest(original_source_string)
    existingRecord = UserSubmittedSourceRecord.where(source_fingerprint: fingerprint).first

    unless existingRecord.nil?  
      pub =  existingRecord.publication
      unless pub.nil?
        pub.update_manual_pub_from_pub_hash(pub_hash, provenance, original_source_string)
      else
        pub = create_man_pub(pub_hash, provenance)
        pub.sync_publication_hash_and_db
      end
    else   
      pub = create_man_pub(pub_hash, provenance)
      # todo:  have to look at deleting old identifiers, old contribution info, from db  i.e, how to correct errors.
      pub.user_submitted_source_records.create(
        is_active: true,
        :source_fingerprint => Digest::SHA2.hexdigest(original_source_string),
        :source_data => original_source_string,
        title: pub_hash[:title],
        year: pub_hash[:year]
      )
      pub.update_any_new_contribution_info_in_pub_hash_to_db
      pub.sync_publication_hash_and_db
      
    end
    pub
  end

def self.create_man_pub(pub_hash, provenance)
  pub_hash[:provenance] = provenance
  Publication.create(
          active: true, 
          title: pub_hash[:title], 
          year: pub_hash[:year], 
          pub_hash: pub_hash, 
          issn: pub_hash[:issn], 
          pages: pub_hash[:pages],
          publication_type: pub_hash[:type])
end

def update_manual_pub_from_pub_hash(incoming_pub_hash, provenance, original_source_string)
    
    incoming_pub_hash[:provenance] = provenance
    self.title = incoming_pub_hash[:title]
    self.year = incoming_pub_hash[:year]
    self.pub_hash = incoming_pub_hash

    self.user_submitted_source_records.first.update_attributes(
        is_active: true,
        :source_fingerprint => Digest::SHA2.hexdigest(original_source_string),
        :source_data => original_source_string,
        title: self.title,
        year: self.year
    )
    self.update_any_new_contribution_info_in_pub_hash_to_db
    self.sync_publication_hash_and_db   
end

#def add_contribution(cap_profile_id, sul_author_id, status, visibility, featured)
#      self.pub_hash[:contributions] = [ {:cap_profile_id => cap_profile_id, :sul_author_id => sul_author_id, :status => status, visibility: visibility, featured: featured}]
#      sync_publication_hash_and_db
#end

def add_any_pubmed_data_to_hash
  unless self.pmid.blank?
    pubmed_hash = PubmedSourceRecord.get_pubmed_hash_for_pmid(self.pmid)
    unless pubmed_hash.nil?
        self.pub_hash[:mesh_headings] = pubmed_hash[:mesh] unless pubmed_hash[:mesh].blank?
        self.pub_hash[:abstract] = pubmed_hash[:abstract] unless pubmed_hash[:abstract].blank?   
    end
  end
end

def set_last_updated_value_in_hash
  save   # to reset last updated value
  self.pub_hash[:last_updated] = updated_at.to_s 
end

def set_sul_pub_id_in_hash
  sul_pub_id = self.id.to_s    
  self.pub_hash[:sulpubid] = sul_pub_id
  self.pub_hash[:identifier] ||= []
  self.pub_hash[:identifier] << {:type => 'SULPubId', :id => sul_pub_id, :url => 'http://sulcap.stanford.edu/publications/' + sul_pub_id}            
end

def cutover_sync_hash_and_db
  set_sul_pub_id_in_hash
  self.pub_hash[:last_updated] = self.updated_at.to_s 
  add_all_db_contributions_to_my_pub_hash
  #add identifiers that are in the hash to the pub identifiers db table
  self.pub_hash[:identifier].each do |identifier|
        self.publication_identifiers.create(
          :identifier_type => identifier[:type],
          :certainty => 'confirmed', 
          :identifier_value => identifier[:id], 
          :identifier_uri => identifier[:url])
  end
 self.class.update_formatted_citations(self.pub_hash)
  save
end

def sync_publication_hash_and_db
    set_last_updated_value_in_hash
    set_sul_pub_id_in_hash
    
    add_all_db_contributions_to_my_pub_hash
    add_any_new_identifiers_in_pub_hash_to_db
    add_all_identifiers_in_db_to_pub_hash
    
    self.class.update_formatted_citations(self.pub_hash)
  
    save
  end

def rebuild_pub_hash
  if self.sciencewire_id
    sw_source_record = SciencewireSourceRecord.where(sciencewire_id: self.sciencewire_id).first
    build_from_sciencewire_hash(sw_source_record.get_source_as_hash)
  elsif self.pmid
    pubmed_source_record = PubmedSourceRecord.where(pmid: self.pmid)
    build_from_pubmed_hash(pubmed_source_record.get_source_as_hash)
  end
  #otherwise, probably manual or batch loaded, so just rebuild identifiers, contributions, and citations from db
  # and update the issn, pages, and pub type
    issn = self.pub_hash[:issn]
    pages = self.pub_hash[:pages]
    publication_type = self.pub_hash[:type]
    self.update_attributes(issn: issn, pages: pages, publication_type: publication_type)
  
    set_last_updated_value_in_hash
    add_all_db_contributions_to_my_pub_hash
    add_all_identifiers_in_db_to_pub_hash
    self.class.update_formatted_citations(self.pub_hash)
    save
end

def rebuild_authorship
  add_all_db_contributions_to_my_pub_hash
  save
end

  def add_any_new_identifiers_in_pub_hash_to_db
    if pub_hash[:identifier] 
      self.pub_hash[:identifier].each do |identifier|
        self.publication_identifiers.where(
          :identifier_type => identifier[:type]).
          first_or_create(:certainty => 'confirmed', :identifier_value => identifier[:id], :identifier_uri => identifier[:url])
      end
    end
  end

def add_all_identifiers_in_db_to_pub_hash
    self.pub_hash[:identifier] = self.publication_identifiers.collect do |identifier|
      ident_hash = Hash.new
      ident_hash[:type] = identifier.identifier_type unless identifier.identifier_type.blank?
      ident_hash[:id] = identifier.identifier_value unless identifier.identifier_value.blank?
      ident_hash[:url] = identifier.identifier_uri unless identifier.identifier_uri.blank?
     ident_hash
    end
  end


def update_any_new_contribution_info_in_pub_hash_to_db
  unless self.pub_hash[:authorship].nil?
    self.pub_hash[:authorship].each do |contrib|
      hash_for_update = {
        status: contrib[:status], 
        visibility: contrib[:visibility],
        featured: contrib[:featured]
      }
      sul_author_id = contrib[:sul_author_id] 
      if sul_author_id.blank? 
        cap_profile_id = contrib[:cap_profile_id]
        unless cap_profile_id.blank?
          author = Author.where(cap_profile_id: contrib[:cap_profile_id]).first
          sul_author_id = author.id unless author.blank? 
        end
      else 
        author = Author.find(sul_author_id)
      end
      cap_profile_id = author.cap_profile_id
      unless cap_profile_id.blank? then hash_for_update[:cap_profile_id] = author.cap_profile_id end
      unless sul_author_id.blank?
        contrib = self.contributions.where(:author_id => sul_author_id).first_or_create   
        contrib.update_attributes(hash_for_update)
      end
    end
  end
end

  def add_all_db_contributions_to_my_pub_hash

  if self.pub_hash && self.pub_hash[:authorship]
      self.pub_hash[:authorship] = self.contributions.collect do |contrib_in_db|     
        {cap_profile_id: contrib_in_db.cap_profile_id,
         sul_author_id: contrib_in_db.author_id,
         status: contrib_in_db.status,
         visibility: contrib_in_db.visibility, 
         featured: contrib_in_db.featured}
      end
      save
    elsif self.pub_hash && ! self.pub_hash[:authorship]
      Logger.new(Rails.root.join('log', 'publications_errors.log')).info("No authorship entry in pub_hash for " + self.id.to_s)
    else
      Logger.new(Rails.root.join('log', 'publications_errors.log')).info("No pub hash for " + self.id.to_s)
    end
  rescue => e
    puts "some problem with hash: #{self.pub_hash}"
    pub_logger = Logger.new(Rails.root.join('log', 'publications_errors.log'))
    pub_logger.error "some problem with adding contributions to the hash for pub #{self.id}"
    pub_logger.error "the hash: #{self.pub_hash}"
    pub_logger.error e.message
    pub_logger.error e.backtrace
  end

  

def self.update_formatted_citations(pub_hash)
    #[{"id"=>"Gettys90", "type"=>"article-journal", "author"=>[{"family"=>"Gettys", "given"=>"Jim"}, {"family"=>"Karlton", "given"=>"Phil"}, {"family"=>"McGregor", "given"=>"Scott"}], "title"=>"The {X} Window System, Version 11", "container-title"=>"Software Practice and Experience", "volume"=>"20", "issue"=>"S2", "abstract"=>"A technical overview of the X11 functionality.  This is an update of the X10 TOG paper by Scheifler \\& Gettys.", "issued"=>{"date-parts"=>[[1990]]}}]
    chicago_csl_file = Rails.root.join('app', 'data', 'chicago-author-date.csl')
    mla_csl_file = Rails.root.join('app', 'data', 'mla.csl')
    apa_csl_file = Rails.root.join('app', 'data', 'apa.csl')
    authors_for_citeproc = []
    authors = pub_hash[:author]
    if authors.length > 5 
      authors = authors[1..4]
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

    # chicago_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/chicago-author-date.csl', :format => 'html')
    # apa_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/apa.csl', :format => 'html')
    # mla_citation = CiteProc.process(cit, :style => 'https://github.com/citation-style-language/styles/raw/master/mla.csl', :format => 'html')
    pub_hash[:apa_citation] = CiteProc.process(cit_data_array, :style => apa_csl_file, :format => 'html')
    pub_hash[:mla_citation] = CiteProc.process(cit_data_array, :style => mla_csl_file, :format => 'html')
    pub_hash[:chicago_citation] = CiteProc.process(cit_data_array, :style => chicago_csl_file, :format => 'html')
    
  end

def update_canonical_xml_for_pub
    xml = "the xml goes here"
  end

end



