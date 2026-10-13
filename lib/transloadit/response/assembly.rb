require "transloadit"

module Transloadit::Response::Assembly
  def reload!
    url = assembly_ssl_url
    raise ArgumentError, "Assembly response does not include a status URL" if url.nil? || url.empty?

    replace Transloadit::Request.new(url).get
  end

  def cancel!
    replace Transloadit::Request.new(self["assembly_ssl_url"]).delete
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
    aborted? || canceled? || completed? || (error? && !status_rate_limit?)
  end

  def uploading?
    self["ok"] == "ASSEMBLY_UPLOADING"
  end

  def rate_limit?
    self["error"] == "RATE_LIMIT_REACHED"
  end

  def status_rate_limit?
    self["error"] == "ASSEMBLY_STATUS_FETCHING_RATE_LIMIT_REACHED"
  end

  def wait_time
    self["info"]&.fetch("retryIn", 0) || 0
  end

  def replace(other)
    assembly_ssl_url
    super
  end

  # Status rate-limit responses omit this URL, so retain it across reloads.
  def assembly_ssl_url
    @assembly_ssl_url ||= self["assembly_ssl_url"]
  end

  DEFAULT_RELOAD_TRIES = 600

  def reload_until_finished!(options = {})
    tries = options[:tries] || DEFAULT_RELOAD_TRIES

    tries.times do
      sleep(status_rate_limit? ? [1, wait_time].max : 1)
      reload!
      return self if finished?
    end

    raise Transloadit::Exception::ReloadLimitReached
  end
end
