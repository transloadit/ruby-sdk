require "transloadit"

module Transloadit::Exception
  #
  # Exception raised when an HTTP request cannot be completed.
  # The original transport error is available through +cause+.
  #
  class RequestFailed < StandardError
  end

  #
  # Exception raised when Rate limit error response is returned from the API.
  # See {Rate Limiting}[https://transloadit.com/docs/api-docs/#rate-limiting]
  #
  class RateLimitReached < StandardError
    # @return [Transloadit::Response] the API response that reported the rate limit
    attr_reader :response

    def initialize(response)
      @response = response
      super("Transloadit Rate Limit Reached. Retry in #{response.wait_time} seconds")
    end
  end

  #
  # Exception raised when Response#reload_until_finished! reaches limit specified in :tries option
  #
  class ReloadLimitReached < StandardError
    def message
      "reload_until_finished! reached limit specified in :tries option. This is not a rate limit and you may continue to poll for updates."
    end
  end

  # Exception raised when an API response does not contain valid JSON.
  class InvalidResponse < StandardError
    # @return [Integer] the HTTP status of the invalid response
    attr_reader :status

    # @return [String] the original body, which may contain sensitive diagnostics
    attr_reader :raw_body

    def initialize(status:, raw_body:)
      @status = status
      @raw_body = raw_body
      super("Transloadit returned invalid JSON (HTTP #{status})")
    end
  end
end
