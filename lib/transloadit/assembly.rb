require 'transloadit'

#
# Represents a Assembly ready to be sent to the REST API for processing. An
# Assembly can contain one or more Steps for processing or point to a
# server-side template. It's submitted along with a list of files to process,
# at which point Transloadit will process and store the files according to the
# rules in the Assembly.
#
# See the Transloadit {documentation}[http://transloadit.com/docs/assemblies]
# for futher information on Assemblies and their parameters.
#
class Transloadit::Assembly
  # @return [Transloadit] the associated Transloadit instance
  attr_reader   :transloadit
  
  # @return [Hash] the options describing the Assembly
  attr_accessor :options
  
  #
  # Creates a new Assembly authenticated using the given +transloadit+
  # instance.
  #
  # @param [Transloadit] transloadit the associated Transloadit instance
  # @param [Hash]        options     the configuration for the Assembly
  #
  def initialize(transloadit, options = {})
    self.transloadit = transloadit
    self.options     = options
  end
  
  #
  # @return [Hash] the processing steps, formatted for sending to Transloadit
  #
  def steps
    _wrap_steps_in_hash options[:steps]
  end
  
  def submit!(*ios)
    # TODO: process upload
  end
  
  #
  # @return [String] a human-readable version of the Assembly
  #
  def inspect
    self.to_hash.inspect
  end
  
  #
  # @return [Hash] a Transloadit-compatible Hash of the Assembly's contents
  #
  def to_hash
    self.options.merge(
      :auth  => self.transloadit.to_hash,
      :steps => self.steps,
    ).delete_if {|k,v| v.nil? }
  end
  
  #
  # @return [String] JSON-encoded String containing the Assembly's contents
  #
  def to_json
    self.to_hash.to_json
  end
  
  protected
  
  attr_writer :transloadit
  
  private
  
  #
  # Returns a Transloadit-compatible Hash wrapping the +steps+ passed to it.
  # Accepts any supported format the +steps+ could come in.
  #
  # @param  [nil, Hash, Step, Array] steps the steps to encode
  # @return [Hash] the Transloadit-compatible hash of steps
  #
  def _wrap_steps_in_hash(steps)
    case steps
      when nil                then steps
      when Hash               then steps
      when Transloadit::Step  then steps.to_hash
      else
        steps.inject({}) {|h, s| h.update s }
    end
  end
end
