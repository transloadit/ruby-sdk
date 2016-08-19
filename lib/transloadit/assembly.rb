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
  # @overload create!(*ios)
  #   @param [Array<IO>] *ios   the files for the assembly to process
  #
  # @overload create!(*ios, params = {})
  #   @param [Array<IO>] *ios   the files for the assembly to process
  #   @param [Hash]      params additional POST data to submit with the request
  #
  def create!(*ios)
    params = _extract_options!(ios)
    params[:steps] = _wrap_steps_in_hash(params[:steps]) if !params[:steps].nil?

    extra_params = {}
    # update the payload with file entries
    ios.each_with_index {|f, i| extra_params.update :"file_#{i}" => f }

    extra_params.merge!(self.options[:fields]) if self.options[:fields]

    _do_request(
      '/assemblies',
      params, 'post',
      extra_params
    ).extend!(Transloadit::Response::Assembly)
  end

  #
  # alias for create!
  # keeping this method for backward compatibility
  #
  def submit!(*ios)
    warn "#{caller(1)[0]}: warning: Transloadit::Assembly#submit!"\
      " is deprecated. use Transloadit::Assembly#create! instead"
    self.create!(*ios)
  end

  #
  # Returns a list of all assemblies
  # @param [Hash]        additional GET data to submit with the request
  #
  def list(params = {})
    _do_request('/assemblies', params)
  end

  #
  # Returns a single assembly object specified by the assembly id
  # @param [String]     id    id of the desired assembly
  #
  def get(id)
    _do_request("/assemblies/#{id}").extend!(Transloadit::Response::Assembly)
  end

  #
  # Replays an assambly specified by the  id
  # @param [String]   id       id of the desired assembly
  # @param [Hash]     params   additional POST data to submit with the request
  #
  def replay(id, params = {})
    _do_request("/assemblies/#{id}/replay", params, 'post').extend!(Transloadit::Response::Assembly)
  end

  #
  # Returns all assembly notifications
  # @param [Hash]        params    additional GET data to submit with the request
  #
  def notifications(params = {})
    _do_request "/assembly_notifications", params
  end

  #
  # Replays an assambly notification by the  id
  # @param [String]      id         id of the desired assembly
  # @param [Hash]        params     additional POST data to submit with the request
  #
  def replay_notification(id, params = {})
    _do_request("/assembly_notifications/#{id}/replay", params, 'post')
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
    ).delete_if {|k,v| v.nil?}
  end

  #
  # @return [String] JSON-encoded String containing the Assembly's contents
  #
  def to_json
    MultiJson.dump(self.to_hash)
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
  def _extract_options!(args)
    args.last.is_a?(Hash) ? args.pop : {}
  end

  #
  # Performs http request in favour of it's caller
  #
  # @param [String]     path      url path to which request is made
  # @param [Hash]       params    POST/GET data to submit with the request
  # @param [String]     method    http request method. This could be 'post' or 'get'
  # @param [Hash]       extra_params   additional POST/GET data to submit with the request
  #
  # @return [Transloadit::Response] the response
  #
  def _do_request(path, params = nil, method = 'get', extra_params = nil)
    if !params.nil?
      params = self.to_hash.update(params)
      params = { :params => params } if method == 'post'
      params.merge!(extra_params) if !extra_params.nil?
    end
    Transloadit::Request.new(path, self.transloadit.secret).public_send(method, params)
  end
end
