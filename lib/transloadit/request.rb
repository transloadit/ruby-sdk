require "transloadit"

require "faraday"
require "faraday/multipart"
require "mime/types"
require "openssl"

#
# Wraps requests to the Transloadit API. Ensures all API requests return a
# parsed Transloadit::Response, and abstracts away finding a lightly-used
# instance on startup.
#
class Transloadit::Request
  # The default Transloadit API endpoint.
  API_ENDPOINT = URI.parse("https://api2.transloadit.com/")

  # The default headers to send to the API.
  API_HEADERS = {"Transloadit-Client" => "ruby-sdk:#{Transloadit::VERSION}"}

  # The HMAC algorithm used for calculation request signatures.
  HMAC_ALGORITHM = OpenSSL::Digest.new("sha384")

  # @return [String] the API endpoint for the request
  attr_reader :url

  # @return [String] the authentication secret to sign the request with
  attr_accessor :secret

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
    self.url = URI.parse(url.to_s)
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
    request! do
      api.get(url.path + to_query(params), nil, API_HEADERS)
    end
  end

  #
  # Performs an HTTP DELETE to the request's URL. Takes an optional hash
  # containing the form-encoded payload.
  #
  # @param  [Hash] payload the payload to form-encode along with the POST
  # @return [Transloadit::Response] the response
  #
  def delete(payload = {})
    request! do
      api.delete(url.path) do |request|
        request.headers.update(API_HEADERS)
        request.body = to_payload(payload)
      end
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
    request! do
      api.post(url.path, to_payload(payload), API_HEADERS)
    end
  end

  #
  # Performs an HTTP PUT to the request's URL. Takes an optional hash
  # containing the form-encoded payload.
  #
  # @param  [Hash] payload the payload to form-encode along with the POST
  # @return [Transloadit::Response] the response
  #
  def put(payload = {})
    request! do
      api.put(url.path, to_payload(payload), API_HEADERS)
    end
  end

  #
  # @return [String] a human-readable version of the prepared Request
  #
  def inspect
    url.to_s.inspect
  end

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

  protected

  attr_writer :url

  #
  # Retrieves the current API endpoint. If the URL of the request contains a
  # hostname, then the hostname is used as the base endpoint of the API.
  # Otherwise uses the class-level API base.
  #
  # @return [Faraday::Connection] the API endpoint for this instance
  #
  def api
    @api ||= case url.host
    when String then connection_for("#{url.scheme}://#{url.host}")
    else connection_for("#{API_ENDPOINT.scheme}://#{API_ENDPOINT.host}")
    end
  end

  def connection_for(base_url)
    Faraday.new(url: base_url) do |connection|
      connection.request :multipart
      connection.request :url_encoded
      connection.adapter Faraday.default_adapter
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
    return {} if payload.respond_to?(:empty?) && payload.empty?

    # Create a new hash with JSONified params and a signature if a secret was provided.
    # Note: We first set :params and :signature to ensure that these are the first fields
    # in the multipart requests, before any file. Otherwise, a signature will only be transmitted
    # after all files have been uploaded. The order of the fields in a multipart request
    # follows the order of the entries in the returned hash here.
    # See https://github.com/transloadit/ruby-sdk/issues/51
    new_payload = {
      params: MultiJson.dump(payload[:params])
    }
    sig = signature(new_payload[:params])
    new_payload[:signature] = sig unless sig.nil?

    payload.each do |key, value|
      next if key == :params || key == :signature

      new_payload[key] = upload?(value) ? multipart_file(value) : value
    end

    new_payload
  end

  def upload?(value)
    value.respond_to?(:read)
  end

  def multipart_file(file)
    path = file.path if file.respond_to?(:path)
    filename = file.original_filename if file.respond_to?(:original_filename)
    filename = File.basename(path) if filename.to_s.empty? && path
    filename = "upload" if filename.to_s.empty?

    content_type = file.content_type if file.respond_to?(:content_type)
    content_type = MIME::Types.type_for(path).first&.content_type if content_type.to_s.empty? && path
    content_type = "application/octet-stream" if content_type.to_s.empty?

    source = path || file
    Faraday::Multipart::FilePart.new(source, content_type, filename)
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
    return "" if params.nil?
    return "" if params.respond_to?(:empty?) && params.empty?

    params_in_json = MultiJson.dump(params)
    uri_params = URI.encode_www_form_component(params_in_json)

    params = {
      params: uri_params,
      signature: signature(params_in_json)
    }

    "?" + params.map { |k, v| "#{k}=#{v}" if v }.compact.join("&")
  end

  #
  # Wraps a request's result in a Transloadit::Response.
  #
  def request!(&request)
    response = yield
    Transloadit::Response.new(
      body: response.body,
      headers: response.headers,
      status: response.status
    )
  rescue Faraday::Error
    raise Transloadit::Exception::RequestFailed, "Transloadit request failed"
  end

  #
  # Computes the HMAC digest of the params hash, if a secret was given to the
  # instance.
  #
  # @param  [String] params the JSON encoded payload to sign
  # @return [String] the HMAC signature for the params
  #
  def signature(params)
    "sha384:" + self.class._hmac(secret, params) if secret.to_s.length > 0
  end
end
