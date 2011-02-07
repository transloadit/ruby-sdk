require 'transloadit'

require 'rest-client'
require 'openssl'

class Transloadit::Request
  API_ENDPOINT = 'http://api2.transloadit.com/'
  API_HEADERS  = { 'User-Agent' => %{Transloadit Ruby SDK #{Transloadit::VERSION}} }
  
  HMAC_ALGORITHM = OpenSSL::Digest::Digest.new('sha1')
  
  attr_reader   :url
  attr_accessor :secret
  attr_accessor :params
    
  def self.api(uri = nil)
    case uri
      when nil then @api ||= RestClient::Resource.new API_ENDPOINT
      else          @api   = RestClient::Resource.new uri
    end
  end
  
  def self.bored!
    self.api self.new('/instances/bored').get['api2_host']
  end
  
  def initialize(url, secret = nil, params = {})
    self.url    = URI.parse(url.to_s)
    self.secret = secret
    self.params = params.to_hash
  end
  
  def api
    @api ||=
      self.url.host ? RestClient::Resource.new(self.url.host) : self.class.api
  end
  
  def get(params = {})
    self.request! do
      self.api[url.path].get(API_HEADERS)
    end
  end
  
  def delete(params = {})
    self.request! do
      self.api[url.path].delete(API_HEADERS)
    end
  end
  
  def post(payload = {})    
    self.request! do
      self.api[url.path].post(self.to_hash.update(payload), API_HEADERS)
    end
  end
  
  def inspect
    self.to_hash.inspect
  end
  
  def to_hash
    { :params    => self.params.to_json,
      :signature => self.signature, }.delete_if {|k,v| v.nil? }
  end
  
  def to_json
    self.to_hash.to_json
  end
  
  protected
  
  attr_writer :url
  
  def request!(&request)
    Transloadit::Response.new(request.call)
  rescue RestClient::Exception => e
    Transloadit::Response.new(e.response)
  end
  
  def signature
    self.class._hmac(self.secret, self.params.to_json) if self.secret
  end
  
  private
  
  def self._hmac(key, message)
    OpenSSL::HMAC.hexdigest HMAC_ALGORITHM, key, message
  end
end
