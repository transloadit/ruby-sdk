require 'json'

#
# Implements the Transloadit REST API in Ruby. Check the {file:README.md README}
# for usage instructions.
#
class Transloadit
  autoload :Assembly, 'transloadit/assembly'
  autoload :Request,  'transloadit/request'
  autoload :Response, 'transloadit/response'
  autoload :Step,     'transloadit/step'
  autoload :VERSION,  'transloadit/version'
  
  # @return [String] your Transloadit auth key
  attr_accessor :key
  
  # @return [String] your Transloadit auth secret, for signing requests
  attr_accessor :secret
  
  #
  # Creates a new instance of the Transloadit API.
  #
  # @param [Hash] options a hash of options, which can be any of:
  # @option options [String] :key your auth key from the
  #   {credentials}[https://transloadit.com/accounts/credentials] page
  #   (required)
  # @option options [String] :secret your auth secret from the
  #   {credentials}[https://transloadit.com/accounts/credentials] page, for
  #   signing requests (optional)
  #
  def initialize(options = {})
    self.key    = options[:key]
    self.secret = options[:secret]
    
    _ensure_key_provided
  end
  
  #
  # Creates a Transloadit::Step describing a step in an upload assembly.
  #
  # @param  [String] robot the robot to use in this step (e.g., '/image/resize')
  # @param  [Hash]   options a hash of options to customize the robot's
  #   operation; see the {Transloadit documentation}[http://transloadit.com/docs/]
  #   for robot-specific options
  # @return [Step]   the created Step
  #
  def step(robot, options = {})
    Transloadit::Step.new(robot, options)
  end
  
  #
  # Creates a Transloadit::Assembly ready to be sent to the REST API.
  #
  # @param [Hash] options additional parameters to send with the assembly
  #   submission; for a full list of parameters, see the official
  #   documentation on {templates}[http://transloadit.com/docs/templates].
  # @option options [Step, Array<Step>] :steps the steps to perform in this
  #   assembly
  # @option options [String] :notify_url A URL to be POSTed when the assembly
  #   has finished processing
  # @option options [String] :template_id the ID of a
  #   {template}[https://transloadit.com/templates] to use instead of
  #   specifying options here directly
  #
  def assembly(options = {})
    Transloadit::Assembly.new(self, options)
  end
  
  #
  # @return [String] a human-readable version of the Transloadit.
  #
  def inspect
    self.to_hash.inspect
  end
  
  #
  # @return [Hash] a Transloadit-compatible Hash of the instance's contents
  #
  def to_hash
    { :key => self.key }.tap do |hash|
      hash.update(:expires => _generate_expiry) unless self.secret.nil?
    end
  end
  
  #
  # @return [String] JSON-encoded String containing the object's hash contents
  #
  def to_json
    self.to_hash.to_json
  end
  
  private
  
  #
  # Raises an ArgumentError if no {#key} has been assigned.
  #
  def _ensure_key_provided
    unless self.key
      raise ArgumentError, 'an authentication key must be provided'
    end
  end
  
  #
  # Automatically generates API-compatible request expiration times 5 minutes
  # from now.
  #
  # @param [Integer] duration the number of seconds from now to set the
  #   expiry time
  # @return [String] an API-compatible timestamp
  #
  def _generate_expiry(duration = 5 * 60)
    (Time.now + duration).utc.strftime('%Y/%m/%d %H:%M:%S+00:00')
  end
end
