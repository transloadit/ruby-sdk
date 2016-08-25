require 'transloadit'

module Transloadit::Response::Template
  def update!(params)
    self.replace Transloadit::Request.new(
      "/templates/#{self['id']}"
    ).post({ :params => params })
  end

  def delete!
    self.replace Transloadit::Request.new("/templates/#{self['id']}").delete
  end

  def created?
    self['ok'] == 'TEMPLATE_CREATED'
  end
end
