require "transloadit"

require "rest-client"

module Transloadit::Exception
  #
  # Exception raised when Rate limit error response is returned from the API.
  # See {Rate Limiting}[https://transloadit.com/docs/api-docs/#rate-limiting]
  #
  class RateLimitReached < RestClient::RequestEntityTooLarge
    def default_message
      retry_msg = " Retry in #{@response.wait_time} seconds" if @response
      "Transloadit Rate Limit Reached.#{retry_msg}"
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
end
