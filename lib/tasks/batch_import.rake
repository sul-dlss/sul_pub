namespace :batch_import do
  desc "ingest publications from bibtex files "
  task :bibtex => :environment do
    BibtexIngester.new.ingest_from_source_directory(Rails.root.join('app', 'data', 'bibtex_to_ingest'))
  end
end
