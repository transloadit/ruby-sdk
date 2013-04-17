require 'transloadit'

module Transloadit::Response::Assembly
  def reload!
    self.replace Transloadit::Request.new(self['assembly_url']).get
  end

  def cancel!
    self.replace Transloadit::Request.new(self['assembly_url']).delete
  end

  def completed?
    self['ok'] == 'ASSEMBLY_COMPLETED'
  end
end
