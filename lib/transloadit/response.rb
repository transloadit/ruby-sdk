require 'transloadit'
require 'delegate'

class Transloadit::Response < Delegator
  autoload :Assembly, 'transloadit/response/assembly'
  
  def initialize(response, &extension)
    self.__setobj__(response)
    
    instance_eval(&extension) if block_given?
  end
  
  def [](attribute)
    self.body[attribute]
  end
  
  def body
    JSON.parse self.__getobj__.body
  end
  
  def inspect
    self.body.inspect
  end
  
  def extend!(mod)
    self.extend(mod)
    self
  end
  
  protected
  
  def __getobj__
    @response
  end
  
  def __setobj__(response)
    @response = response
  end
  
  def replace(other)
    self.__setobj__ other.__getobj__
  end
end
