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
  HMAC_ALGORITHM = OpenSSL::Digest.new('sha1')

  # @return [String] the API endpoint for the request
  attr_reader   :url

  # @return [String] the authentication secret to sign the request with
  attr_accessor :secret

  #
  # Automatically sets the API endpoint to the server with the most free
  # resources. This is called automatically the first time a request is made.
  #
  def self.bored!
    self.api self.bored
  end

  #
  # Prepares a request against an endpoint URL, optionally with an encryption
  # secret. If only a path is passed, the API will automatically determine the
  # best server to use. If a full URL is given, the host provided will be
  # used.
  #
  # @param [String] url    the API endpoint
  # @param [String] secret an optional secret with which to sign the request
  #
  def initialize(url, secret = nil)
    self.url    = URI.parse(url.to_s)
    self.secret = secret
  end

  #
  # Performs an HTTP GET to the request's URL. Takes an optional hash of
  # query params.
  #
  # @param  [Hash] params additional query parameters
  # @return [Transloadit::Response] the response
  #
  def get(params = {})
    self.request! do
      self.api[url.path + self.to_query(params)].get(API_HEADERS)
    end
  end

  #
  # Performs an HTTP DELETE to the request's URL. Takes an optional hash of
  # query params.
  #
  # @param  [Hash] params additional query parameters
  # @return [Transloadit::Response] the response
  #
  def delete(params = {})
    self.request! do
      self.api[url.path + self.to_query(params)].delete(API_HEADERS)
    end
  end

  #
  # Performs an HTTP POST to the request's URL. Takes an optional hash
  # containing the form-encoded payload.
  #
  # @param  [Hash] payload the payload to form-encode along with the POST
  # @return [Transloadit::Response] the response
  #
  def post(payload = {})
    self.request! do
      self.api[url.path].post(self.to_payload(payload), API_HEADERS)
    end
  end

  #
  # @return [String] a human-readable version of the prepared Request
  #
  def inspect
    self.url.to_s.inspect
  end

  protected

  attr_writer :url

  #
  # Locates the API server with the smallest job queue.
  #
  # @return [String] the hostname of the most bored server
  #
  def self.bored
    self.new(API_ENDPOINT + '/instances/bored').get['api2_host']
  end

  #
  # Sets or retrieves the base URI of the API endpoint.
  #
  # @overload self.api
  #   @return [RestClient::Resource] the current API endpoint
  #
  # @overload self.api(uri)
  #   @param [String] the hostname or URI to set the API endpoint to
  #   @return [RestClient::Resource] the new API endpoint
  #
  def self.api(uri = nil)
    @api   = RestClient::Resource.new(uri) if uri
    @api ||= RestClient::Resource.new(self.bored)
  end

  #
  # Retrieves the current API endpoint. If the URL of the request contains a
  # hostname, then the hostname is used as the base endpoint of the API.
  # Otherwise uses the class-level API base.
  #
  # @return [RestClient::Resource] the API endpoint for this instance
  #
  def api
    @api ||= begin
      case self.url.host
        when String then RestClient::Resource.new(self.url.host)
        else self.class.api
      end
    end
  end

  #
  # Updates the POST payload passed to be compliant with the Transloadit API
  # spec. JSONifies the value for the +params+ key and signs the request with
  # the instance's +secret+ if it exists.
  #
  # @param  [Hash] the payload to update
  # @return [Hash] the Transloadit-compliant POST payload
  #
  def to_payload(payload = nil)
    return {} if payload.nil?
    return {} if payload.respond_to?(:empty?) and payload.empty?

    # TODO: refactor this, don't update a hash that's not ours
    payload.update :params    => MultiJson.dump(payload[:params])
    payload.update :signature => self.signature(payload[:params])
    payload.delete :signature if payload[:signature].nil?
    payload
  end

  #
  # Updates the GET/DELETE params hash to be compliant with the Transloadit
  # API by URI escaping and encoding the params hash, and attaching a
  # signature.
  #
  # @param  [Hash] params the params to encode
  # @return [String] the URI-encoded and escaped query parameters
  #
  def to_query(params = nil)
    return '' if params.nil?
    return '' if params.respond_to?(:empty?) and params.empty?

    escape    = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
    params_in_json = MultiJson.dump(params)
    uri_params = URI.escape(params_in_json, escape)

    params    = {
      :params    => uri_params,
      :signature => self.signature(params_in_json)
    }

    '?' + params.map {|k,v| "#{k}=#{v}" if v }.compact.join('&')
  end

  #
  # Wraps a request's results in a Transloadit::Response, even if an exception
  # is raised by RestClient.
  #
  def request!(&request)
    Transloadit::Response.new request.call
  rescue RestClient::Exception => e
    Transloadit::Response.new e.response
  end

  #
  # Computes the HMAC digest of the params hash, if a secret was given to the
  # instance.
  #
  # @param  [String] params the JSON encoded payload to sign
  # @return [String] the HMAC signature for the params
  #
  def signature(params)
    self.class._hmac(self.secret, params) if self.secret.to_s.length > 0
  end

  private

  #
  # Computes an HMAC digest from the key and message.
  #
  # @param  [String] key     the secret key to sign with
  # @param  [String] message the message to sign
  # @return [String]         the signature of the message
  #
  def self._hmac(key, message)
    OpenSSL::HMAC.hexdigest HMAC_ALGORITHM, key, message
  end
end
