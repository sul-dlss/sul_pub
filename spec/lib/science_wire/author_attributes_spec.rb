
describe ScienceWire::AuthorAttributes do
  describe '#initialize' do
    #initialize(name, email, seed_list = [], institution = nil, start_date = nil, end_date = nil)
    subject { described_class.new(nil, nil, [], 0, [], nil) }
    it 'casts name to an AuthorName' do
      expect(subject.name).to be_an ScienceWire::AuthorName
    end
    it 'casts email to a string' do
      expect(subject.email).to be_an String
    end
    it 'casts institution to AuthorInstitution' do
      expect(subject.institution).to be_an ScienceWire::AuthorInstitution
    end
  end
end
