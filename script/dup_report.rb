# frozen_string_literal: true

require 'csv'

class Reporter
  def initialize(swids_file, pmids_file, wos_file)
    @swids = build_id_set swids_file
    @pmids = build_id_set pmids_file
    @wosids = build_id_set wos_file
    @log = Logger.new('pub_dups.log')
    @sw_pub_ids = []
    @pmid_sw_pub_ids = []
    @wos_pub_ids = []
    @all_pub_ids = Set.new
  end

  def build_id_set(filename)
    lines = File.readlines(filename).map(&:strip).compact_blank
    Set.new(lines)
  end

  def work
    @swids.each do |swid|
      Publication.where(sciencewire_id: swid).each do |pub|
        @log.info "Removing pmid #{pub.pmid} from #{pub.id} with swid #{swid}" if @pmids.delete? pub.pmid
        @sw_pub_ids << [swid, pub.id]
        @all_pub_ids.add pub.id
      end
    end

    @pmids.each do |pmid|
      Publication.where(pmid:).each do |pub|
        if @all_pub_ids.add? pub.id
          @pmid_sw_pub_ids << [pmid, pub.sciencewire_id, pub.id]
        else
          @log.info "Dup already found - pubid:#{pub.id} pmid:#{pmid}"
        end
      end
    end

    @wosids.each do |wosid|
      ids = PublicationIdentifier.where(identifier_type: 'WoSItemID', identifier_value: wosid).pluck(:publication_id)
      ids.each do |id|
        if @all_pub_ids.add? id
          @wos_pub_ids << [wosid, id]
        else
          @log.info "Dup already found - pubid:#{id} wosid:#{wosid}"
        end
      end
    end

    CSV.open('sw_pub_ids.csv', 'w') do |csv|
      csv << %w[sciencewire_id sulpubid]
      @sw_pub_ids.each { |a| csv << a }
    end

    CSV.open('pmid_sw_pub_ids.csv', 'w') do |csv|
      csv << %w[pubmedid sciencewire_id sulpubid]
      @pmid_sw_pub_ids.each { |a| csv << a }
    end

    CSV.open('wos_pub_ids.csv', 'w') do |csv|
      csv << %w[wosid sulpubid]
      @wos_pub_ids.each { |a| csv << a }
    end
  end
end

r = Reporter.new('/Users/wmene/dev/cap/dup_sw_ids.txt', '/Users/wmene/dev/cap/dup_pmids.txt',
                 '/Users/wmene/dev/cap/dup_wos.txt')
r.work
