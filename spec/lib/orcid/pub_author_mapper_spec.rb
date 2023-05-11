# frozen_string_literal: true

describe Orcid::PubAuthorMapper do
  let(:contributor) { described_class.map(author_hash) }

  let(:author_hash) do
    {
      display_name:,
      first_name:,
      firstname:,
      full_name:,
      given_name:,
      initials:,
      middle_name:,
      middlename:,
      last_name:,
      lastname:,
      name:,
      role:
    }
  end

  let(:display_name) { '' }
  let(:first_name) { '' }
  let(:firstname) { '' }
  let(:full_name) { '' }
  let(:given_name) { '' }
  let(:initials) { '' }
  let(:middle_name) { '' }
  let(:middlename) { '' }
  let(:last_name) { '' }
  let(:lastname) { '' }
  let(:name) { '' }
  let(:role) { '' }

  describe '#map' do
    context 'when name provided' do
      let(:name) { 'Samuel Clemens' }
      let(:full_name) { 'Samuel Langhorne Clemens' }

      it 'prefers name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Samuel Clemens'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when dirty name provided - A' do
      let(:name) { 'Clemens,Samuel,' }

      it 'cleans name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Clemens, Samuel'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when dirty name provided - B' do
      let(:name) { 'Clemens,Samuel,L' }

      it 'cleans name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Clemens, Samuel L.'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when dirty name provided - C' do
      let(:name) { 'Clemens,Samuel M.,L' }

      it 'cleans name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Clemens, Samuel M. L.'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when dirty name provided - D' do
      let(:name) { 'Clemens,S,L' }

      it 'cleans name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Clemens, S. L.'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when full_name provided' do
      let(:full_name) { 'Samuel Langhorne Clemens' }
      let(:display_name) { 'Samuel Clemens' }

      it 'prefers full_name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Samuel Langhorne Clemens'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when display_name provided' do
      let(:display_name) { 'Samuel Clemens' }
      let(:first_name) { 'Sam' }
      let(:last_name) { 'Clemens' }

      it 'prefers full_name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Samuel Clemens'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when underscore name parts provided' do
      let(:first_name) { 'Samuel' }
      let(:middle_name) { 'Langhorne' }
      let(:last_name) { 'Clemens' }
      let(:firstname) { 'Sam' }
      let(:middlename) { 'Lang' }
      let(:lastname) { 'Clemens' }

      it 'prefers underscore name parts' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Samuel Langhorne Clemens'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when name parts provided' do
      let(:firstname) { 'Samuel' }
      let(:middlename) { 'Langhorne' }
      let(:lastname) { 'Clemens' }

      it 'builds name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Samuel Langhorne Clemens'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when given name provided' do
      let(:given_name) { 'Samuel' }
      let(:middlename) { 'Langhorne' }
      let(:lastname) { 'Clemens' }

      it 'builds name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Samuel Langhorne Clemens'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when initials provided' do
      let(:initials) { 'S.L.' }
      let(:lastname) { 'Clemens' }

      it 'builds name' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'S.L. Clemens'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'author'
                                    }
                                  })
      end
    end

    context 'when role provided' do
      let(:name) { 'Mark Twain' }
      let(:role) { 'support-staff' }

      it 'sets role' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Mark Twain'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'support-staff'
                                    }
                                  })
      end
    end

    context 'when mapped role provided' do
      let(:name) { 'Mark Twain' }
      let(:role) { 'book_editor' }

      it 'sets role' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Mark Twain'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': 'editor'
                                    }
                                  })
      end
    end

    context 'when unknown role provided' do
      let(:name) { 'Mark Twain' }
      let(:role) { 'pen name' }

      it 'sets role to null' do
        expect(contributor).to eq({
                                    'contributor-orcid': nil,
                                    'credit-name': {
                                      value: 'Mark Twain'
                                    },
                                    'contributor-email': nil,
                                    'contributor-attributes': {
                                      'contributor-sequence': nil,
                                      'contributor-role': nil
                                    }
                                  })
      end
    end

    context 'when filtered role provided' do
      let(:name) { 'IEEE' }
      let(:role) { 'corp' }

      it 'skips' do
        expect(contributor).to be_nil
      end
    end

    context 'when blank name provided' do
      let(:name) { '' }
      let(:role) { 'book_editor' }

      it 'skips' do
        expect(contributor).to be_nil
      end
    end
  end
end
