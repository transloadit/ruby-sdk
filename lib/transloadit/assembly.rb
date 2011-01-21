require 'transloadit'

class Transloadit::Assembly
  attr_reader   :transloadit
  attr_accessor :options
  
  def initialize(transloadit, options = {})
    self.transloadit = transloadit
    self.options     = options
  end
  
  def steps
    _wrap_steps_in_hash options[:steps]
  end
  
  def submit!(*ios)
    # TODO: process upload
  end
  
  def inspect
    self.to_hash.inspect
  end
  
  def to_hash
    self.options.merge(
      :auth  => self.transloadit.to_hash,
      :steps => self.steps
    )
  end
  
  def to_json
    self.to_hash.to_json
  end
  
  protected
  
  attr_writer :transloadit
  
  def _wrap_steps_in_hash(steps)
    case steps
      when nil                then steps
      when Hash               then steps
      when Transloadit::Step  then steps.to_hash
      else
        steps.inject({}) {|h, s| h.update s }
    end
  end
end
