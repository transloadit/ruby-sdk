class Transloadit
  attr_accessor :key
  attr_accessor :secret
  
  #
  # Creates a new instance of the Transloadit API.
  #
  # @param [Hash] options a hash of options, which can be any of:
  #
  #   [key]    your auth key from the 
  #            {credentials}[https://transloadit.com/accounts/credentials]
  #            page (required)
  #   [secret] your auth secret from the
  #            {credentials}[https://transloadit.com/accounts/credentials]
  #            page, for signing requests (optional)
  #
  def initialize(options = {})
    self.key    = options[:key]
    self.secret = options[:secret]
    
    _ensure_key_provided
  end
  
  private
  
  def _ensure_key_provided
    unless self.key
      raise ArgumentError, 'an authentication key must be provided'
    end
  end
end
