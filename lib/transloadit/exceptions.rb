require 'transloadit'

require 'rest-client'

module Transloadit::Exception
  class RateLimitReached < RestClient::RequestEntityTooLarge

    def default_message
      retry_msg =  " Retry in #{@response.wait_time} seconds" if @response
      "Transloadit Rate Limit Reached.#{retry_msg}"
    end
  end
end
