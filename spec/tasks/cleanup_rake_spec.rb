require 'rake'

describe 'cleanup rake tasks' do
  before(:all) do
    Rake.application.rake_require 'tasks/cleanup'
    Rake::Task.define_task(:environment)
  end
  before(:each) do
    Rake::Task['cleanup:merge_profiles'].reenable
    allow($stdout).to receive(:puts)
  end

  describe 'merge profiles task' do
    let(:primary_author) do
      auth = create :author, id: 1, cap_profile_id: 123
      allow(auth).to receive(:publications).and_return [build(:publication, id: 1), build(:publication, id: 2)]
      allow(auth).to receive(:contributions).and_return [Contribution.new(id: 1, publication_id: 1), Contribution.new(publication_id: 2, author_id: 1)]
      auth
    end
    let(:duped_author) do
      auth = create :author, id: 2, cap_profile_id: 456, cap_import_enabled: true, active_in_cap: true
      # the dup calls are because we set mutually exclusive expectations on the in-memory object
      allow(auth).to receive(:publications).and_return [primary_author.publications.last.dup, build(:publication, id: 3)]
      allow(auth).to receive(:contributions).and_return [Contribution.new(publication_id: 2, author_id: 2), Contribution.new(id: 3, publication_id: 3)]
      auth
    end

    it 'raises an exception if no parameters are supplied' do
      expect { Rake.application.invoke_task 'cleanup:merge_profiles' }.to raise_error(RuntimeError)
    end

    it 'call the correct methods on publication and authors when running the cleanup task' do
      allow(Author).to receive(:find_by_cap_profile_id).with('123').and_return primary_author
      allow(Author).to receive(:find_by_cap_profile_id).with('456').and_return duped_author

      # primary author contributions are never saved or removed
      primary_author.contributions.each do |contribution|
        expect(contribution).not_to receive(:save)
        expect(contribution).not_to receive(:destroy)
      end

      # the primary authors pubs will be rebuilt
      primary_author.publications.each do |pub|
        expect(pub).to receive(:sync_publication_hash_and_db)
        expect(pub).to receive(:save)
      end
      # the duped authors pubs do not need to rebuilt
      duped_author.publications.each do |pub|
        expect(pub).not_to receive(:sync_publication_hash_and_db)
        expect(pub).not_to receive(:save)
      end

      Rake.application.invoke_task 'cleanup:merge_profiles[123,456]'

      # the first duped author contribution is destroyed because it already exists in the primary author profile (publication_id = 2)
      # the second duped author contribution is moved to the primary author's profile because it does not yet exist there
      expect(duped_author.contributions[0]).to be_destroyed
      expect(duped_author.contributions[1]).not_to be_destroyed
      expect(duped_author.contributions[1].author_id).to eq(primary_author.id)
      expect(duped_author.contributions[1].cap_profile_id).to eq(primary_author.cap_profile_id)

      # the duped author is set to inactive
      duped_author.reload
      expect(duped_author.cap_import_enabled).to eq(false)
      expect(duped_author.active_in_cap).to eq(false)
    end
  end
end
