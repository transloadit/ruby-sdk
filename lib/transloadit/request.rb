require 'transloadit'

require 'rest-client'
require 'openssl'

class Transloadit::Request
  API_ENDPOINT = 'http://api2.transloadit.com/'
  API_HEADERS  = { 'User-Agent' => %{Transloadit Ruby SDK #{Transloadit::VERSION}} }
  
  HMAC_ALGORITHM = OpenSSL::Digest::Digest.new('sha1')
  
  attr_accessor :url
  attr_accessor :secret
  attr_accessor :params
    
  def self.api(uri = nil)
    case uri
      when nil then @api ||= RestClient::Resource.new API_ENDPOINT
      else          @api   = RestClient::Resource.new uri
    end
  end
  
  def self.bored!
    self.api self.get('/instances/bored')['api2_host']
  end
  
  def self.get(url)
    api[url].get(API_HEADERS)
  end
  
  def self.delete(url)
    api[url].delete(API_HEADERS)
  end
  
  def self.post(url, payload)
    api[url].post(payload, API_HEADERS) {|a,b,c| [a,b,c] }
  end
  
  def initialize(url, secret = nil, params = {})
    self.url    = url
    self.secret = secret
    self.params = params.to_hash
  end
  
  def get
    self.class.get url
  end
  
  def delete
    self.class.delete url
  end
  
  def post(params = {})
    self.class.post url, self.to_hash.merge(params)
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
  
  def signature
    self.class._hmac(self.secret, self.params.to_json) if self.secret
  end
  
  private
  
  def self._hmac(key, message)
    OpenSSL::HMAC.hexdigest HMAC_ALGORITHM, key, message
  end
end
