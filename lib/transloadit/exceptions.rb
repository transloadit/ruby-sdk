require 'transloadit'

require 'rest-client'

#
# Transloadit custom Exception classes
#
module Transloadit::Exception

  #
  # Exception raised when Rate limit error response is returned from the API.
  # See {Rate Limiting}[https://transloadit.com/docs/api-docs/#rate-limiting]
  #
  class RateLimitReached < RestClient::RequestEntityTooLarge

    def default_message
      retry_msg =  " Retry in #{@response.wait_time} seconds" if @response
      "Transloadit Rate Limit Reached.#{retry_msg}"
    end
  end
end
