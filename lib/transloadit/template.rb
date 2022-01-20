require 'transloadit'

#
# Represents a Template API ready to interact with its corresponding REST API.
#
# See the Transloadit {documentation}[https://transloadit.com/docs/api/templates/]
# for futher information on Templates and their parameters.
#
class Transloadit::Template < Transloadit::ApiModel
  #
  # Submits a template to be created.
  #
  # @param [Hash]  params POST data to submit with the request.
  #   must contain keys 'name' and 'template'
  #
  # @option params [String] :name name assigned to the newly created template
  # @option params [Hash] :template key, value pair of template content
  #   see {template}[https://transloadit.com/templates]
  #
  def create(params)
    _do_request('/templates', params, 'post')
  end

  #
  # Returns a list of all templates
  # @param [Hash]    additional GET data to submit with the request
  #
  def list(params = {})
    _do_request('/templates', params)
  end

  #
  # Returns a single template object specified by the template id
  # @param [String]     id    id of the desired template
  # @param [Hash]    additional GET data to submit with the request
  #
  def get(id, params = {})
    _do_request("/templates/#{id}", params)
  end

  #
  # Updates the template object specified by the template id
  # @param [String]     id    id of the desired template
  # @param [Hash]    additional POST data to submit with the request
  #   must contain keys 'name' and 'template'
  #
  # @option params [String] :name name assigned to the newly created template
  # @option params [Hash] :template key, value pair of template content
  #   see {template}[https://transloadit.com/templates]
  #
  def update(id, params = {})
    _do_request("/templates/#{id}", params, 'put')
  end

  #
  # Deletes the template object specified by the template id
  # @param [String]     id    id of the desired template
  # @param [Hash]    additional POST data to submit with the request
  #
  def delete(id, params = {})
    _do_request("/templates/#{id}", params, 'delete')
  end
end
