require 'spec_helper'

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
