# frozen_string_literal: true

require 'transloadit'

require 'rest-client'
require 'delegate'

module Transloadit
  class Response < Delegator
    autoload :Assembly, 'transloadit/response/assembly'

    #
    # Creates an enhanced response wrapped around a RestClient response.
    #
    # @param [RestClient::Response] response the JSON response to wrap
    #
    def initialize(response)
      __setobj__(response)
    end

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
      MultiJson.load __getobj__.body
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

    protected

    #
    # The object to delegate method calls to.
    #
    # @return [RestClient::Response]
    #
    def __getobj__
      @response
    end

    #
    # Sets the object to delegate method calls to.
    #
    # @param  [RestClient::Response] response the response to delegate to
    # @return [RestClient::Response]          the delegated response
    #
    def __setobj__(response)
      @response = response
    end

    #
    # Replaces the object this instance delegates to with the one the other
    # object uses.
    #
    # @param  [Delegator] other       the object whose delegate to use
    # @return [Transloadit::Response] this response
    #
    def replace(other)
      __setobj__ other.__getobj__
      self
    end
  end
end
