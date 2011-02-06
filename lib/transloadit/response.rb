require 'transloadit'
require 'delegate'

class Transloadit::Response < Delegator  
  def initialize(response, &extension)
    self.__setobj__(response)
    
    instance_eval(&extension)
  end
  
  def [](attribute)
    self.body[attribute]
  end
  
  def body
    JSON.parse(super)
  end
  
  def inspect
    self.body.inspect
  end
  
  protected
  
  def __getobj__
    @response
  end
  
  def __setobj__(response)
    @response = response
  end
end
