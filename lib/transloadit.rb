require "multi_json"
require "date"

#
# Implements the Transloadit REST API in Ruby. Check the {file:README.md README}
# for usage instructions.
#
class Transloadit
  autoload :ApiModel, "transloadit/api_model"
  autoload :Assembly, "transloadit/assembly"
  autoload :Exception, "transloadit/exception"
  autoload :Request, "transloadit/request"
  autoload :Response, "transloadit/response"
  autoload :SmartCDN, "transloadit/smart_cdn"
  autoload :Step, "transloadit/step"
  autoload :Template, "transloadit/template"
  autoload :VERSION, "transloadit/version"

  # @return [String] your Transloadit auth key
  attr_accessor :key

  # @return [String] your Transloadit auth secret, for signing requests
  attr_accessor :secret

  # @return [Integer] the duration in seconds that signed API requests
  #   generated from this instance remain valid
  attr_accessor :duration

  attr_accessor :max_size

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
    self.key = options[:key]
    self.secret = options[:secret]
    self.duration = options[:duration] || 5 * 60
    self.max_size = options[:max_size]

    _ensure_key_provided
  end

  #
  # Creates a Transloadit::Step describing a step in an upload assembly.
  #
  # @param  [String] name  the name to give the step
  # @param  [String] robot the robot to use in this step (e.g., '/image/resize')
  # @param  [Hash]   options a hash of options to customize the robot's
  #   operation; see the {online documentation}[https://transloadit.com/docs/building-assembly-instructions]
  #   for robot-specific options
  # @return [Step]   the created Step
  #
  def step(name, robot, options = {})
    Transloadit::Step.new(name, robot, options)
  end

  #
  # Creates a Transloadit::Assembly ready to be sent to the REST API.
  #
  # @param [Hash] options additional parameters to send with the assembly
  #   submission; for a full list of parameters, see the official
  #   documentation on {templates}[https://transloadit.com/docs/templates].
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
  # Creates a Transloadit::Template instance ready to interact with its corresponding REST API.
  #
  # See the Transloadit {documentation}[https://transloadit.com/docs/api-docs/#template-api]
  # for further information on Templates and available endpoints.
  #
  def template(options = {})
    Transloadit::Template.new(self, options)
  end

  #
  # Gets user billing reports for specified month and year.
  # Defaults to current month or year if corresponding param is not specified.
  #
  # @param [Integer] month the month for which billing reports should be retrieved.
  #   defaults to current month if not specified.
  # @param [Integer] year the year for which billing reports should be retrieved.
  #   defaults to current year if not specified.
  #
  def bill(month = Date.today.month, year = Date.today.year)
    # convert month to 2 digit format
    month = format "%02d", month
    path = "bill/#{year}-#{month}"

    Transloadit::Request.new(path, secret).get({auth: to_hash})
  end

  #
  # @return [String] a human-readable version of the Transloadit.
  #
  def inspect
    to_hash.inspect
  end

  #
  # @return [Hash] a Transloadit-compatible Hash of the instance's contents
  #
  def to_hash
    result = {key: key}
    result.update(max_size: max_size) unless max_size.nil?
    result.update(expires: _generate_expiry) unless secret.nil?
    result
  end

  #
  # @return [String] JSON-encoded String containing the object's hash contents
  #
  def to_json
    MultiJson.dump(to_hash)
  end

  private

  #
  # Raises an ArgumentError if no {#key} has been assigned.
  #
  def _ensure_key_provided
    unless key
      raise ArgumentError, "an authentication key must be provided"
    end
  end

  #
  # Generates an API-compatible request expiration timestamp. Uses the
  # current instance's duration.
  #
  # @return [String] an API-compatible timestamp
  #
  def _generate_expiry
    (Time.now + duration).utc.strftime("%Y/%m/%d %H:%M:%S+00:00")
  end
end
