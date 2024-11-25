require 'openssl'
require 'uri'
require 'cgi'

class Transloadit
  class SmartCDN
    # @param workspace [String] Workspace slug
    # @param template [String] Template slug or template ID
    # @param input [String] Input value that is provided as `${fields.input}` in the template
    # @param auth_key [String] Authentication key
    # @param auth_secret [String] Authentication secret
    # @param url_params [Hash] Additional parameters for the URL query string (optional)
    # @param expire_in_ms [Integer] Expiration time in milliseconds from now (optional)
    # @param expire_at_ms [Integer] Expiration time as Unix timestamp in milliseconds (optional)
    # @return [String] Signed Smart CDN URL
    def self.signed_url(workspace:, template:, input:, auth_key:, auth_secret:, url_params: {}, expire_in_ms: nil, expire_at_ms: nil)
      raise ArgumentError, 'workspace is required' if workspace.nil? || workspace.empty?
      raise ArgumentError, 'template is required' if template.nil? || template.empty?
      raise ArgumentError, 'input is required' if input.nil?

      workspace_slug = CGI.escape(workspace)
      template_slug = CGI.escape(template)
      input_field = CGI.escape(input)

      expire_at = if expire_at_ms
                   expire_at_ms
                 elsif expire_in_ms
                   (Time.now.to_f * 1000).to_i + expire_in_ms
                 else
                   (Time.now.to_f * 1000).to_i + (1 * 60 * 60 * 1000) # 1 hour default
                 end

      query_params = {}
      url_params.each do |key, value|
        next if value.nil?
        if value.is_a?(Array)
          value.each do |val|
            next if val.nil?
            (query_params[key.to_s] ||= []) << val.to_s
          end
        else
          query_params[key.to_s] = [value.to_s]
        end
      end

      query_params['auth_key'] = [auth_key]
      query_params['exp'] = [expire_at.to_s]

      # Sort parameters to ensure consistent ordering
      sorted_params = query_params.sort.map do |key, values|
        values.compact.map { |v| "#{CGI.escape(key)}=#{CGI.escape(v)}" }
      end.flatten.reject(&:empty?).join('&')

      string_to_sign = "#{workspace_slug}/#{template_slug}/#{input_field}?#{sorted_params}"

      signature = OpenSSL::HMAC.hexdigest('sha256', auth_secret, string_to_sign)

      final_params = "#{sorted_params}&sig=#{CGI.escape("sha256:#{signature}")}"
      "https://#{workspace_slug}.tlcdn.com/#{template_slug}/#{input_field}?#{final_params}"
    end
  end
end
