require 'transloadit'

module Transloadit::Response::Assembly
  def reload!
    self.replace Transloadit::Request.new(self['assembly_url']).get
  end

  def cancel!
    self.replace Transloadit::Request.new(self['assembly_url']).delete
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

  def executing?
    self['ok'] == 'ASSEMBLY_EXECUTING'
  end

  def uploading?
    self['ok'] == 'ASSEMBLY_UPLOADING'
  end
end
