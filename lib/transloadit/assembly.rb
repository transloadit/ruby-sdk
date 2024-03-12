require "transloadit"

#
# Represents an Assembly API ready to make calls to the REST API endpoints.
#
# See the Transloadit {documentation}[https://transloadit.com/docs/api-docs/#assembly-api]
# for further information on Assemblies and available endpoints.
#
class Transloadit::Assembly < Transloadit::ApiModel
  DEFAULT_TRIES = 3

  #
  # @return [Hash] the processing steps, formatted for sending to Transloadit
  #
  def steps
    _wrap_steps_in_hash options[:steps]
  end

  #
  # Creates a Transloadit::Assembly and sends to the REST API. An
  # Assembly can contain one or more Steps for processing or point to a
  # server-side template. It's submitted along with a list of files to process,
  # at which point Transloadit will process and store the files according to the
  # rules in the Assembly.
  # See the Transloadit {documentation}[https://transloadit.com/docs/building-assembly-instructions]
  # for further information on Assemblies and their parameters.
  #
  # Accepts as many IO objects as you wish to process in the assembly.
  # The last argument is an optional Hash
  # of parameters to send along with the request.
  #
  # @overload create!(*ios)
  #   @param [Array<IO>] *ios   the files for the assembly to process
  #
  # @overload create!(*ios, params = {})
  #   @param [Array<IO>] *ios   the files for the assembly to process
  #   @param [Hash]      params additional POST data to submit with the request;
  #     for a full list of parameters, see the official documentation
  #     on {templates}[https://transloadit.com/docs/templates].
  #   @option params [Step, Array<Step>] :steps the steps to perform in this
  #     assembly
  #   @option params [String] :notify_url A URL to be POSTed when the assembly
  #     has finished processing
  #   @option params [String] :template_id the ID of a
  #     {template}[https://transloadit.com/templates] to use instead of
  #     specifying params here directly
  #
  def create!(*ios, **params)
    params[:steps] = _wrap_steps_in_hash(params[:steps]) unless params[:steps].nil?

    extra_params = {}
    extra_params.merge!(options[:fields]) if options[:fields]

    trials = options[:tries] || DEFAULT_TRIES
    (1..trials).each do |trial|
      # update the payload with file entries
      ios.each_with_index { |f, i| extra_params.update "file_#{i}": f }

      response = _do_request(
        "/assemblies", params, "post", extra_params
      ).extend!(Transloadit::Response::Assembly)

      return response unless response.rate_limit?

      _handle_rate_limit!(response, ios, trial < trials)
    end
  end

  #
  # alias for create!
  # keeping this method for backward compatibility
  #
  def submit!(*ios)
    warn "#{caller(1..1).first}: warning: Transloadit::Assembly#submit!" \
      " is deprecated. use Transloadit::Assembly#create! instead"
    create!(*ios)
  end

  #
  # Returns a list of all assemblies
  # @param [Hash]        additional GET data to submit with the request
  #
  def list(params = {})
    _do_request("/assemblies", params)
  end

  #
  # Returns a single assembly object specified by the assembly id
  # @param [String]     id    id of the desired assembly
  #
  def get(id)
    _do_request("/assemblies/#{id}").extend!(Transloadit::Response::Assembly)
  end

  #
  # Replays an assembly specified by the  id
  # @param [String]   id       id of the desired assembly
  # @param [Hash]     params   additional POST data to submit with the request
  #
  def replay(id, params = {})
    params[:wait] = false
    _do_request("/assemblies/#{id}/replay", params, "post").extend!(Transloadit::Response::Assembly)
  end

  #
  # Returns all assembly notifications
  # @param [Hash]        params    additional GET data to submit with the request
  #
  def get_notifications(params = {})
    _do_request "/assembly_notifications", params
  end

  #
  # Replays an assembly notification by the  id
  # @param [String]      id         id of the desired assembly
  # @param [Hash]        params     additional POST data to submit with the request
  #
  def replay_notification(id, params = {})
    _do_request("/assembly_notifications/#{id}/replay", params, "post")
  end

  #
  # @return [Hash] a Transloadit-compatible Hash of the Assembly's contents
  #
  def to_hash
    options.merge(
      auth: transloadit.to_hash,
      steps: steps
    ).delete_if { |k, v| v.nil? }
  end

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
    when nil then steps
    when Hash then steps
    when Transloadit::Step then steps.to_hash
    else
      if steps.uniq(&:name) != steps
        raise ArgumentError, "There are different Assembly steps using the same name"
      end
      steps.inject({}) { |h, s| h.update s }
    end
  end

  #
  # Stays idle for certain time and then reopens assembly files for reprocessing.
  # Should be called when assembly rate limit is reached.
  #
  # @param  [Response] response  assembly response that comes with a rate limit
  # @param [Array<IO>] ios the files sent for the assembly to process.
  #
  def _handle_rate_limit!(response, ios, is_retrying)
    if is_retrying
      warn "Rate limit reached. Waiting for #{response.wait_time} seconds before retrying."
      sleep response.wait_time
      # RestClient closes file streams at the end of a request.
      ios.collect! { |file| File.open file.path }
    else
      raise Transloadit::Exception::RateLimitReached.new(response)
    end
  end
end
