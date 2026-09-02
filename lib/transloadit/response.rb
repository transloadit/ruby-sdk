require "transloadit"

class Transloadit::Response
  autoload :Assembly, "transloadit/response/assembly"

  #
  # Creates a response without exposing the underlying HTTP client.
  #
  # @param [String] body the raw response body
  # @param [Hash] headers the response headers
  # @param [Integer] status the HTTP response status
  #
  def initialize(body:, headers:, status:)
    @raw_body = body
    @headers = normalize_headers(headers)
    @status = status
  end

  # @return [Hash] normalized response headers
  attr_reader :headers

  # @return [Integer] the HTTP response status
  attr_reader :status

  # RestClient exposed the status through +code+ in previous SDK versions.
  alias_method :code, :status

  #
  # Returns the attribute from the JSON response.
  #
  # @param  [String] attribute the attribute name to look up
  # @return [String]           the value for the attribute
  #
  def [](attribute)
    body[attribute.to_s]
  end

  #
  # Returns the parsed JSON body.
  #
  # @return [Hash] the parsed JSON body hash
  #
  def body
    MultiJson.load @raw_body
  end

  #
  # Inspects the body of the response.
  #
  # @return [String] a human-readable version of the body
  #
  def inspect
    body.inspect
  end

  #
  # Chainably extends the response with additional methods. Used to add
  # context-specific functionality to a response.
  #
  # @param  [Module] mod            the module to extend with
  # @return [Transloadit::Response] the extended response
  #
  def extend!(mod)
    extend(mod)

    self
  end

  #
  # Replaces this response's HTTP data with another response's data.
  #
  # @param  [Transloadit::Response] other the response whose data to use
  # @return [Transloadit::Response] this response
  #
  def replace(other)
    @raw_body = other.raw_body
    @headers = other.headers
    @status = other.status
    self
  end

  protected

  attr_reader :raw_body

  private

  def normalize_headers(headers)
    headers.to_h.each_with_object({}) do |(name, value), normalized|
      normalized[name.to_s.downcase.tr("-", "_").to_sym] = value
    end
  end
end
