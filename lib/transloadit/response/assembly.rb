require "transloadit"

module Transloadit::Response::Assembly
  def reload!
    replace Transloadit::Request.new(self["assembly_url"]).get
  end

  def cancel!
    replace Transloadit::Request.new(self["assembly_url"]).delete
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
