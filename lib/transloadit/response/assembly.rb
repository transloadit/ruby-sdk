require 'transloadit'

module Transloadit::Response::Assembly
  def reload!
    replace Transloadit::Request.new(self['assembly_url']).get
  end

  def cancel!
    replace Transloadit::Request.new(self['assembly_url']).delete
  end

  def aborted?
    self['ok'] == 'REQUEST_ABORTED'
  end

  def canceled?
    self['ok'] == 'ASSEMBLY_CANCELED'
  end

  def completed?
    self['ok'] == 'ASSEMBLY_COMPLETED'
  end

  def error?
    self['error'] != nil
  end

  def executing?
    self['ok'] == 'ASSEMBLY_EXECUTING'
  end

  def finished?
    aborted? || canceled? || completed? || error?
  end

  def uploading?
    self['ok'] == 'ASSEMBLY_UPLOADING'
  end
end
