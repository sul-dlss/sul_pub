# frozen_string_literal: true

require 'csv'
require 'pathname'

ActiveRecord::Base.logger.level = 1

class String
  def snakecase
    # gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .gsub(/\s/, '_')
      .gsub(/__+/, '_')
      .downcase
  end
end

class Dept
  attr_accessor :name, :books, :pubs

  def initialize(n)
    @name = n
    @books = []
    @pubs = []
  end
end

Pub = Struct.new(:type, :title, :journal_title, :pub_date, :provenance, :profile_id)
Book = Struct.new(:type, :title, :chapt_title, :pub_date, :provenance, :profile_id)

class TitleReport
  def initialize
    @processed_ids = Set.new
    @book_ids = []
    @all_depts = []
    @current_dept = Dept.new 'dummy'
    @logger = Logger.new(Rails.root.join('log/title_report.log'))
    @logger.formatter = proc { |severity, datetime, _progname, msg|
      "#{severity} #{datetime}[#{Process.pid}]: #{msg}\n"
    }
  end

  def parse_lines(file)
    raw = File.read file
    @lines = raw.split("\r")
  end

  def profile_names(file)
    parse_lines file

    @lines.each do |l|
      _, prof_id = l.split(',')
      @logger.warn "Skipping duplicate profile_id in line: #{l}" if @processed_ids.member? prof_id
      @processed_ids << prof_id
    end

    CSV.open('/tmp/report/all_official_first_last_names.csv', 'w') do |csv|
      csv << %w[cap_profile_id official_first_last_name]
      @processed_ids.each do |id|
        auth = Author.where(cap_profile_id: id).first
        csv << [id, "#{auth.official_first_name} #{auth.official_last_name}"]
      end
    end
  end

  def work(file)
    parse_lines file
    @count = 0
    @lines.each do |line|
      @count += 1
      begin
        parse_line line
      rescue StandardError => e
        @logger.error "Skipping line: #{line}\n#{e.inspect}\n#{e.backtrace.join("\n")}"
      end
      @logger.info "Processed #{@count}" if @count % 1000 == 0
    end

    generate_report
  end

  def parse_line(l)
    dept, prof_id = l.split(',')
    if @processed_ids.member? prof_id
      @logger.warn "Skipping duplicate profile_id in line: #{l}"
      return
    end
    @processed_ids << prof_id

    unless dept =~ /#{@current_dept.name}/
      @logger.info "New Dept: #{dept}"
      @current_dept = Dept.new dept
      @all_depts << @current_dept
    end

    process_id prof_id
  end

  def process_id(id)
    auths = Author.where(cap_profile_id: id)
    if auths.size != 1
      @logger.warn "Found #{auths.size} auths for #{id}. skipping"
      return
    end
    auth = auths.first

    pubs = auth.publications
    pubs.each do |pub|
      pub_hash = pub.pub_hash
      case pub_hash[:type]
      when 'book'
        @book_ids << pub.id
        process_book pub_hash, auth.cap_profile_id
      when 'inbook'
        process_inbook pub_hash, auth.cap_profile_id
      else
        process_journ pub_hash, auth.cap_profile_id
      end
    end
  end

  def process_inbook(pub_hash, prof_id)
    p = Book.new
    p.type = pub_hash[:type]
    p.title = pub_hash[:booktitle]
    p.chapt_title = pub_hash[:title]
    p.pub_date = pub_hash[:year]
    p.provenance = pub_hash[:provenance]
    p.profile_id = prof_id
    @current_dept.books << p
  end

  def process_book(pub_hash, prof_id)
    p = Book.new
    p.type = pub_hash[:type]
    p.title = pub_hash[:booktitle]
    p.pub_date = pub_hash[:year]
    p.provenance = pub_hash[:provenance]
    p.profile_id = prof_id
    @current_dept.books << p
  end

  def process_journ(pub_hash, prof_id)
    p = Pub.new
    p.type = pub_hash[:type]
    p.title = pub_hash[:title]
    if pub_hash[:journal]
      p.journal_title = pub_hash[:journal][:name]
    else
      @logger.warn "Article has no journal, sulpubid: #{pub_hash[:sulpubid]}"
    end
    p.pub_date = pub_hash[:year]
    p.provenance = pub_hash[:provenance]
    p.profile_id = prof_id
    @current_dept.pubs << p
  end

  def generate_report
    @report_root = Pathname.new '/tmp/report'
    @report_root.rmtree if @report_root.exist?
    @report_root.mkdir
    @all_depts.each do |dept|
      process_pubs dept
      process_books dept
    end
  end

  def process_pubs(dept)
    title_counter = {}
    dept.pubs.each do |pub|
      title = pub.journal_title
      title_counter[title] = if title_counter.include? title
                               title_counter[title] + 1
                             else
                               1
                             end
    end

    CSV.open(@report_root + "#{dept.name.snakecase}_unique_journals.csv", 'w') do |csv|
      csv << %w[journal_title count]
      title_counter.sort_by { |_k, v| v }.reverse!.each do |k, v|
        csv << [k, v]
      end
    end

    dept.pubs.sort! { |a, b| a.profile_id <=> b.profile_id }
    CSV.open(@report_root + "#{dept.name.snakecase}_all_journals.csv", 'w') do |csv|
      csv << %i[type title journal_title pub_date provenance profile_id]
      dept.pubs.each do |p|
        csv << [p.type, p.title, p.journal_title, p.pub_date, p.provenance, p.profile_id]
      end
    end
  end

  def process_books(dept)
    dept.books.sort! { |a, b| a.profile_id <=> b.profile_id }
    CSV.open(@report_root + "#{dept.name.snakecase}_all_books.csv", 'w') do |csv|
      csv << %i[type title chapt_title pub_date provenance profile_id]
      dept.books.each do |p|
        csv << [p.type, p.title, p.chapt_title, p.pub_date, p.provenance, p.profile_id]
      end
    end
  end
end

# r = TitleReport.new
# r.work '/path/to/input'
