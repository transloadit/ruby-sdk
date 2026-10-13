require "transloadit"
require "securerandom"

module Transloadit::Response::Assembly
  # @return [Transloadit, nil] the client used to authenticate Assembly actions
  attr_accessor :transloadit

  def reload!
    replace Transloadit::Request.new(self["assembly_ssl_url"]).get
  end

  def cancel!
    return replace Transloadit::Request.new(self["assembly_ssl_url"]).delete unless transloadit

    auth = transloadit.to_hash
    # Separate cancellation attempts must not produce the same signed payload.
    auth[:nonce] = SecureRandom.uuid unless transloadit.secret.to_s.empty?
    replace Transloadit::Request.new(self["assembly_ssl_url"], transloadit.secret)
      .delete(params: {auth: auth})
  end

  def aborted?
    self["ok"] == "REQUEST_ABORTED"
  end

  def canceled?
    self["ok"] == "ASSEMBLY_CANCELED"
  end

  def completed?
    self["ok"] == "ASSEMBLY_COMPLETED"
  end

  def error?
    self["error"] != nil
  end

  def executing?
    self["ok"] == "ASSEMBLY_EXECUTING"
  end

  def replaying?
    self["ok"] == "ASSEMBLY_REPLAYING"
  end

  def finished?
    aborted? || canceled? || completed? || error?
  end

  def uploading?
    self["ok"] == "ASSEMBLY_UPLOADING"
  end

  def rate_limit?
    self["error"] == "RATE_LIMIT_REACHED"
  end

  def wait_time
    self["info"]["retryIn"] || 0
  end

  DEFAULT_RELOAD_TRIES = 600

  def reload_until_finished!(options = {})
    tries = options[:tries] || DEFAULT_RELOAD_TRIES

    tries.times do
      sleep 1
      reload!
      return self if finished?
    end

    raise Transloadit::Exception::ReloadLimitReached
  end
end
