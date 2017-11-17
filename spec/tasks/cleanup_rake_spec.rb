require 'rake'

describe 'cleanup rake tasks' do
  before :all do
    Rake.application.rake_require "tasks/cleanup"
    Rake::Task.define_task(:environment)
  end

  describe 'merge profiles task' do
    before :each do
      Rake::Task["cleanup:merge_profiles"].reenable
    end

    it 'raises an exception if no parameters are supplied' do
      expect { Rake.application.invoke_task "cleanup:merge_profiles" }.to raise_error(RuntimeError)
    end

    it 'call the correct methods on publication and authors when running the cleanup task' do
      primary_author = Author.new(id: 1, cap_profile_id: 123)
      duped_author = Author.new(id: 2, cap_profile_id: 456)
      primary_author_pubs = [Publication.new(id: 1), Publication.new(id: 2)]
      duped_author_pubs = [Publication.new(id: 2), Publication.new(id: 3)]
      primary_author_contributions = [Contribution.new(publication_id: 1), Contribution.new(publication_id: 2)]
      duped_author_contributions = [Contribution.new(publication_id: 2), Contribution.new(publication_id: 3)]

      allow(Author).to receive(:find_by_cap_profile_id).with("123").and_return primary_author
      allow(Author).to receive(:find_by_cap_profile_id).with("456").and_return duped_author
      allow(primary_author).to receive(:publications).and_return primary_author_pubs
      allow(duped_author).to receive(:publications).and_return duped_author_pubs
      allow(primary_author).to receive(:contributions).and_return primary_author_contributions
      allow(duped_author).to receive(:contributions).and_return duped_author_contributions

      # primary author contributions are never saved or removed
      primary_author_contributions.each do |contribution|
        expect(contribution).not_to receive(:save)
        expect(contribution).not_to receive(:destroy)
      end

      # the first duped author contribution is destroyed because it already exists in the primary author profile (publication_id = 2)
      expect(duped_author_contributions[0]).to receive(:destroy)

      # the second duped author contribution is moved to the primary author's profile because it does not yet exist there
      expect(duped_author_contributions[1]).to receive('author_id=').with(primary_author.id)
      expect(duped_author_contributions[1]).to receive('cap_profile_id=').with(primary_author.cap_profile_id)
      expect(duped_author_contributions[1]).to receive(:save)

      # the primary authors pubs will be rebuilt
      primary_author_pubs.each do |pub|
        expect(pub).to receive(:sync_publication_hash_and_db)
        expect(pub).to receive(:save)
      end
      # the duped authors pubs do not need to rebuilt
      duped_author_pubs.each do |pub|
        expect(pub).not_to receive(:sync_publication_hash_and_db)
        expect(pub).not_to receive(:save)
      end

      # both authors are reloaded
      expect(primary_author).to receive(:reload)
      expect(duped_author).to receive(:reload)

      # the duped author is set to inactive
      expect(duped_author).to receive('cap_import_enabled=').with(false)
      expect(duped_author).to receive('active_in_cap=').with(false)
      expect(duped_author).to receive(:save)

      Rake.application.invoke_task "cleanup:merge_profiles[123,456]"
    end
  end
end
