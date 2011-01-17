class Transloadit
  autoload :Robot, 'transloadit/robot'
  
  # @return [String] your Transloadit auth key
  attr_accessor :key
  
  # @return [String] your Transloadit auth secret, for signing requests
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
  
  #
  # Creates a Transloadit::Robot describing a step in an upload assembly.
  #
  # @param  [String] type the type of robot to create (e.g., '/image/resize')
  # @param  [Hash]   options a hash of options to customize the robot.
  # @return [Robot]  the created Robot
  #
  def robot(type, options = {})
    Transloadit::Robot.new(type, options)
  end
  
  private
  
  def _ensure_key_provided
    unless self.key
      raise ArgumentError, 'an authentication key must be provided'
    end
  end
end
