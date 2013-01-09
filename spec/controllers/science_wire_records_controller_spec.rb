require 'spec_helper'

describe ScienceWireRecordsController do
  describe 'searching ScienceWire API' do
    it 'should call the model method that searches ScienceWire' do
    	get :search, {search_terms: 'Stanford jones'}
    end
    it 'should select the Search Results template for rendering'
    it 'should make the search results available to the template'
  end
end