require 'transloadit'

#
# Implements the concept of a step in the Transloadit API. Each Step has a
# +robot+ (e.g., '/image/resize' or '/video/thumbnail') and a hash of
# +options+ specific to the chosen robot.
#
# See the Transloadit {documentation}[http://transloadit.com/docs/building-assembly-instructions]
# for futher information on robot types and their parameters.
#
class Transloadit::Step
  # @return [String] the robot to use
  attr_reader :robot
  
  # @return [Hash] the robot's options
  attr_accessor :options
  
  #
  # Creates a new Step with the given +robot+.
  #
  # @overload step(robot, options = {})
  #   @param [String] robot   the robot to use
  #   @param [Hash]   options the configuration options for the robot; see
  #     {Transloadit#step} for possible values
  #
  # @overload step(robot, name, options = {})
  #   @param [String] robot   the robot to use
  #   @param [String] name    the explicit name to give the step
  #   @param [Hash]   options the configuration options for the robot; see
  #     {Transloadit#step} for possible values
  #
  def initialize(robot, *options)
    self.robot   = robot
    self.options = _extract_options!(options)
    self.name    = options.first
  end
  
  #
  # Automatically generates a unique, 32-character hex name for the step that
  # uses this robot.
  #
  # @return [String] a randomly generated name
  #
  def name
    # rand() is "good enough" for this; we generate 128 random bits (same
    # length as a UUID for future compatibility) and convert it to hex
    @name ||= rand(2 ** 128).to_s(16).rjust(32, '0')
  end
  
  #
  # Specifies that this Step should process the provided +input+ instead of
  # the output of the Step before it.
  #
  # @param [Step, Array<Step>, Symbol, nil] input The input
  #   step to use. Follows the conventions outlined in the
  #   online  {documentation}[http://transloadit.com/docs/building-assembly-instructions#special-parameters].
  #   The symbol +:original+ specifies that the original file should be sent
  #   to the robot. A Step indicates that this Step's output should be used
  #   as the input to this one. Likewise, an array of Steps tells Transloadit
  #   to use pass each of their outputs to this Step. And lastly, an explicit
  #   nil clears the setting and restores it to its default input.
  #
  # @return [String, Array<String>, nil> The value for the +:use+ parameter
  #   that will actually be sent to the REST API.
  #
  def use(input)
    self.options.delete(:use) and return if input.nil?
    
    self.options[:use] = case input
      when Symbol then input.inspect
      when Array  then input.map {|i| i.name }
      else             [ input.name ]
    end
  end
  
  #
  # @return [String] a human-readable version of the Step
  #
  def inspect
    self.to_hash[self.name].inspect
  end
  
  #
  # @return [Hash] a Transloadit-compatible Hash of the Step's contents
  #
  def to_hash
    { self.name => options.merge(:robot => self.robot) }
  end
  
  #
  # @return [String] JSON-encoded String containing the Step's hash contents
  #
  def to_json
    self.to_hash.to_json
  end
  
  protected
  
  attr_writer :robot
  attr_writer :name
  
  private
  
  #
  # Extracts the last argument from a set of arguments if it's a hash.
  # Otherwise, returns an empty hash.
  #
  # @param  *args  the arguments to search for an options hash
  # @return [Hash] the options passed, otherwise an empty hash
  #
  def _extract_options!(args)
    args.last.is_a?(Hash) ? args.pop : {}
  end
end
