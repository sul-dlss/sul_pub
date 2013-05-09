class SchemasController < ApplicationController
  def article
    render :file => Rails.root.join('app', 'data', 'json_schemas', 'article.json'),
      :content_type => 'application/json',
      :layout => false
	end
	def book
    render :file => Rails.root.join('app', 'data', 'json_schemas', 'book.json'),
      :content_type => 'application/json',
      :layout => false
	end
	def inproceedings
    render :file => Rails.root.join('app', 'data', 'json_schemas', 'inproceedings.json'),
      :content_type => 'application/json',
      :layout => false
	end
end


