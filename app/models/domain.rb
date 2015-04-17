# For the benefit of NewDomainWorker
require "nokogiri"

class Domain < ActiveRecord::Base
  # Lookup and cache meta information for a domain
  def self.lookup_meta(domain_name)
    # TODO If the last time the meta info was grabbed was a long time ago, refresh it
    domain = ActiveRecord::Base.transaction do
      find_by(name: domain_name) || create!(lookup_metadata_remote(domain_name).merge(name: domain_name))
    end
    domain.meta
  end

  def self.lookup_metadata_remote(domain_name)
    begin
      doc = RestClient::Resource.new("http://#{domain_name}", verify_ssl: OpenSSL::SSL::VERIFY_NONE).get
      header = Nokogiri::HTML(doc).at("html head")
      tag = header.at("meta[name='description']") || header.at("meta[name='Description']")
      meta = tag["content"] if tag
      {meta: meta, title: header.at("title").inner_text}
    rescue RestClient::InternalServerError, RestClient::BadRequest, RestClient::ResourceNotFound, RestClient::Forbidden, Errno::ECONNREFUSED
      {meta: nil, title: nil}
    end
  end
end