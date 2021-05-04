require "transloadit"

#
# Represents an API class that more Transloadit specific API classes
# would inherit from.
#
class Transloadit::ApiModel
  # @return [Transloadit] the associated Transloadit instance
  attr_reader :transloadit

  # @return [Hash] the options describing the Assembly
  attr_accessor :options

  #
  # Creates a new API instance authenticated using the given +transloadit+
  # instance.
  #
  # @param [Transloadit] transloadit the associated Transloadit instance
  # @param [Hash]        options     the configuration for the API;
  #
  def initialize(transloadit, options = {})
    self.transloadit = transloadit
    self.options = options
  end

  #
  # @return [String] a human-readable version of the API
  #
  def inspect
    to_hash.inspect
  end

  #
  # @return [Hash] a Transloadit-compatible Hash of the API's contents
  #
  def to_hash
    options.merge(
      auth: transloadit.to_hash
    ).delete_if { |_, v| v.nil? }
  end

  #
  # @return [String] JSON-encoded String containing the API's contents
  #
  def to_json
    MultiJson.dump(to_hash)
  end

  protected

  attr_writer :transloadit

  private

  #
  # Performs http request in favour of it's caller
  #
  # @param [String]     path      url path to which request is made
  # @param [Hash]       params    POST/GET data to submit with the request
  # @param [String]     method    http request method. This could be 'post' or 'get'
  # @param [Hash]       extra_params   additional POST/GET data to submit with the request
  #
  # @return [Transloadit::Response] the response
  #
  def _do_request(path, params = nil, method = "get", extra_params = nil)
    if !params.nil?
      params = to_hash.update(params)
      params = {params: params} if ["post", "put", "delete"].include? method
      params.merge!(extra_params) unless extra_params.nil?
    end
    Transloadit::Request.new(path, transloadit.secret).public_send(method, params)
  end
end
