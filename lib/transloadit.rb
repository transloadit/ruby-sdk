class Transloadit
  attr_accessor :key
  attr_accessor :secret
  
  def initialize(options = {})
    self.key    = options[:key]
    self.secret = options[:secret]
    
    _ensure_key_provided
  end
  
  private
  
  def _ensure_key_provided
    unless self.key
      raise ArgumentError, 'an authentication key must be provided'
    end
  end
end
