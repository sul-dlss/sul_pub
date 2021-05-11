# frozen_string_literal: true

FactoryBot.define do
  factory :contribution do
    status { 'approved' }
    visibility { 'public' }
    featured { true }
    author
    publication
  end
end
