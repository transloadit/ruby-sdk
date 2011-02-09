require 'transloadit'

require 'rest-client'
require 'openssl'

#
# Wraps requests to the Transloadit API. Ensures all API requests return a
# parsed Transloadit::Response, and abstracts away finding a lightly-used
# instance on startup.
#
class Transloadit::Request
  # The default Transloadit API endpoint.
  API_ENDPOINT = URI.parse('http://api2.transloadit.com/')
  
  # The default headers to send to the API.
  API_HEADERS  = { 'User-Agent' => %{Transloadit Ruby SDK #{Transloadit::VERSION}} }
  
  # The HMAC algorithm used for calculation request signatures.
  HMAC_ALGORITHM = OpenSSL::Digest::Digest.new('sha1')
  
  # @return [String] the API endpoint for the request
  attr_reader   :url
  
  # @return [String] the authentication secret to sign the request with
  attr_accessor :secret
  
  def self.bored!
    self.api(self.bored)
  end
  
  def initialize(url, secret = nil)
    self.url    = URI.parse(url.to_s)
    self.secret = secret
  end
  
  def get(params = {})
    self.request! do
      self.api[url.path + self.to_query(params)].get(API_HEADERS)
    end
  end
  
  def delete(params = {})
    self.request! do
      self.api[url.path + self.to_query(params)].delete(API_HEADERS)
    end
  end
  
  def post(payload = {})
    self.request! do
      self.api[url.path].post(self.to_payload(payload), API_HEADERS)
    end
  end
  
  def inspect
    self.url.to_s.inspect
  end
  
  protected
  
  attr_writer :url
  
  def self.bored
    self.new(API_ENDPOINT + '/instances/bored').get['api2_host']
  end
  
  def self.api(uri = nil)
    @api   = RestClient::Resource.new(uri) if uri
    @api ||= RestClient::Resource.new(self.bored)
  end
  
  def api
    @api ||= begin
      case self.url.host
        when String then RestClient::Resource.new(self.url.host)
        else self.class.api
      end
    end
  end
  
  def to_payload(payload = nil)
    return {} if payload.nil?
    return {} if payload.respond_to?(:empty?) and payload.empty?
    
    # TODO: refactor this, don't update a hash that's not ours
    payload.update :params    => payload[:params].to_json
    payload.update :signature => self.signature(payload[:params])
    payload.delete :signature if payload[:signature].nil?
    payload
  end
  
  def to_query(params = nil)
    return '' if params.nil?
    return '' if params.respond_to?(:empty?) and params.empty?
    
    escape = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
    params = URI.escape(params.to_json, escape)
    
    # TODO: fix this to not depend on to_hash
    '?' + self.to_hash.
      update(:params => params).
      map {|k,v| "#{k}=#{v}" }.
      join('&')
  end
  
  def request!(&request)
    Transloadit::Response.new request.call
  rescue RestClient::Exception => e
    Transloadit::Response.new e.response
  end
  
  def signature(params)
    self.class._hmac(self.secret, params.to_json) if self.secret
  end
  
  private
  
  def self._hmac(key, message)
    OpenSSL::HMAC.hexdigest HMAC_ALGORITHM, key, message
  end
end
