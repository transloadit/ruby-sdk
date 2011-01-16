require 'transloadit'
require 'json'

class Transloadit::Robot
  attr_reader   :type
  attr_accessor :options
  
  def initialize(type, options = {})
    self.type    = type
    self.options = options
  end
  
  def name
    @name ||= rand(2 ** 160).to_s(16)
  end
  
  def use(input)
    self.options.delete(:use) and return if input.nil?
    
    self.options[:use] = case input
      when Symbol then input.inspect
      when Array  then input.map(&:name)
      else             [ input.name ]
    end
  end
  
  def to_h
    { self.name => options.merge(:robot => type) }
  end
  
  def to_json
    self.to_h.to_json
  end
  
  protected
  
  attr_writer   :type
  attr_accessor :input
end
