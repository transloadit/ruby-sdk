require 'transloadit'

#
# Represents a Assembly ready to be sent to the REST API for processing. An
# Assembly can contain one or more Steps for processing or point to a
# server-side template. It's submitted along with a list of files to process,
# at which point Transloadit will process and store the files according to the
# rules in the Assembly.
#
# See the Transloadit {documentation}[http://transloadit.com/docs/building-assembly-instructions]
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
  # @param [Hash]        options     the configuration for the Assembly;
  #   see {Transloadit#assembly}
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
  
  #
  # Submits the assembly for processing. Accepts as many IO objects as you
  # wish to process in the assembly. The last argument is an optional Hash
  # of parameters to send along with the request.
  #
  # @overload submit!(*ios)
  #   @param [Array<IO>] *ios   the files for the assembly to process
  #
  # @overload submit!(*ios, params = {})
  #   @param [Array<IO>] *ios   the files for the assembly to process
  #   @param [Hash]      params additional POST data to submit with the request
  #
  def submit!(*ios)
    params  = _extract_options!(*ios)
    payload = { :params => self.to_hash.update(params) }
    
    ios.each_with_index {|f, i| payload.update :"file_#{i}" => f }
    
    request = Transloadit::Request.new '/assemblies',
      self.transloadit.secret
    
    request.post(payload).extend!(Transloadit::Response::Assembly)
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
      :steps => self.steps
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
  
  #
  # Extracts the last argument from a set of arguments if it's a hash.
  # Otherwise, returns an empty hash.
  #
  # @param  *args  the arguments to search for an options hash
  # @return [Hash] the options passed, otherwise an empty hash
  #
  def _extract_options!(*args)
    args.last.is_a?(Hash) ? args.pop : {}
  end
end
