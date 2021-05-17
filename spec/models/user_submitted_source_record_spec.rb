# frozen_string_literal: true

describe UserSubmittedSourceRecord, type: :model do
  let(:user_submitted_source_record) { create :user_submitted_source_record }
  let(:working_paper) { create :working_paper }
  let(:case_study) { create :case_study }
  let(:technical_report) { create :technical_report }
  let(:other_paper) { create :other_paper }

  context 'default' do
    it 'has factory' do
      expect(user_submitted_source_record).to be_a described_class
    end

    it 'is BibJSON' do
      json = { pub_hash: JSON.parse(user_submitted_source_record.source_data) }
      expect(json).to be_a Hash
      expect(json).to include(:pub_hash)
      expect(json[:pub_hash]).to be_a Hash
      expect(json[:pub_hash]['title']).to match(/^An improved TSVD-based Levenberg-Marquard/)
    end
  end

  context 'working_paper' do
    it 'has factory' do
      expect(working_paper).to be_a described_class
    end
  end

  context 'case_study' do
    it 'has factory' do
      expect(case_study).to be_a described_class
    end
  end

  context 'technical_report' do
    it 'has factory' do
      expect(technical_report).to be_a described_class
    end
  end

  context 'other_paper' do
    it 'has factory' do
      expect(other_paper).to be_a described_class
    end
  end
end
