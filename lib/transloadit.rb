require 'json'

#
# Implements the Transloadit REST API in Ruby. Check the {file:README.md README}
# for usage instructions.
#
class Transloadit
  autoload :Assembly, 'transloadit/assembly'
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
  #
  #   [+:key+]    your auth key from the 
  #               {credentials}[https://transloadit.com/accounts/credentials]
  #               page (required)
  #   [+:secret+] your auth secret from the
  #               {credentials}[https://transloadit.com/accounts/credentials]
  #               page, for signing requests (optional)
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
  # @param  [Hash]   options a hash of options to customize the robot
  # @return [Step]   the created Step
  #
  def step(robot, options = {})
    Transloadit::Step.new(robot, options)
  end
  
  #
  # Creates a Transloadit::Assembly ready to be sent to the REST API.
  #
  # @param [Hash] options a hash of options taken by the API, including:
  #
  #   [+:steps+]       a Step or Array of Steps that describes the processing
  #                    to be performed by this assembly
  #   [+:notify_url+]  a URL to be POST to when the Assembly has completed
  #   [+:template_id+] the ID of a {template}[http://transloadit.com/docs/templates]
  #                    to base this assembly off of from, which can be found on
  #                    your account's {templates}[https://transloadit.com/templates]
  #                    page
  #
  def assembly(*options)
    Transloadit::Assembly.new(self, *options)
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
    { :key    => self.key,
      :secret => self.secret }.delete_if {|_,v| v.nil? }
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
end
