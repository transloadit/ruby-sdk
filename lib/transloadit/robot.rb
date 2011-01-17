require 'transloadit'
require 'json'

#
# Implements the concept of a robot in the Transloadit API. Each Robot has a
# +type+ (e.g., '/image/resize' or '/video/thumbnail') and a hash of +options+
# specific to the Robot's type.
#
# See the Transloadit {documentation}[http://transloadit.com/docs/assemblies]
# for futher information on specific robots and their parameters.
#
class Transloadit::Robot
  # @return [String] the type of robot
  attr_reader   :type
  
  # @return [Hash] the robot's options
  attr_accessor :options
  
  #
  # Creates a new Robot of the given +type+.
  #
  # @param [String] type the type of Robot to create
  # @param [Hash]   options the robot's configuration options
  #
  def initialize(type, options = {})
    self.type    = type
    self.options = options
  end
  
  #
  # Automatically generates a unique name for the step that uses this robot.
  #
  # @return [String] a randomly generated name
  #
  def name
    @name ||= rand(2 ** 160).to_s(16)
  end
  
  #
  # Specifies that this Robot should process the provided +input+ instead of
  # the output of the step before it.
  #
  # @param [Robot, Array<Robot>, Symbol, nil] input The input
  #   step to use. Follows the conventions outlined in the
  #   online  {documentation}[http://transloadit.com/docs/assemblies#special-parameters].
  #   The symbol +:original+ specifies that the original file should be sent
  #   to the robot. A Robot indicates that that Robot's output should be used
  #   as the input to this one. Likewise, an array of Robots tells Transloadit
  #   to use pass each of their outputs to this Robot. And lastly, an explicit
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
  # @return [String] a human-readable version of the Robot
  #
  def inspect
    self.to_h[self.name].inspect
  end
  
  #
  # @return [Hash] a Transloadit-compatible Hash of the Robot's contents
  #
  def to_h
    { self.name => options.merge(:robot => type) }
  end
  
  #
  # @return [String] JSON-encoded String containing the Robot's hash contents
  #
  def to_json
    self.to_h.to_json
  end
  
  protected
  
  attr_writer :type
end
