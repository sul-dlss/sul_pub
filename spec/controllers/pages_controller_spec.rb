require 'spec_helper'

describe HighVoltage::PagesController, '#show' do
  %w(api authorshipapi bibtex pollapi pubapi pubsapi queryapi).each do |page|
    context 'on GET to /#{page}' do
      before do
        get :show, :id => page
      end

      it { expect(response.status).to eq(200) }
      it { expect(response).to render_template("pages/" + page) }
    end
  end

  %w(schemas/article.json schemas/book.json schemas/inproceedings.json api_samples/get_pub_out.json api_samples/get_pubs_out.json api_samples/post_pub_in.json).each do |page|
    context 'on GET to /#{page}' do
      before do
        get :show, :id => page
      end

      it { expect(response.status).to eq(200) }
      it { is_expected.to render_template("pages/" + page) }
    end
  end

  %w(api_samples/post_pub_in.bibtex).each do |page|
    context 'on GET to /#{page}' do
      before do
        get :show, :id => page
      end

      it { expect(response.status).to eq(200) }
      it { is_expected.to render_template("pages/" + page) }
    end
  end

end