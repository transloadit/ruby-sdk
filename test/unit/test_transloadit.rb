require 'test_helper'

describe Transloadit do
  before do
    @key    = 'a'
    @secret = 'b'
  end
  
  it 'must allow initialization' do
    t = Transloadit.new(:key => @key, :secret => @secret)
    t.must_be_kind_of Transloadit
  end
  
  it 'must not be initialized with no arguments' do
    lambda { Transloadit.new }.must_raise ArgumentError
  end
  
  it 'must require a key' do
    lambda { Transloadit.new(:secret => @secret) }.must_raise ArgumentError
  end
  
  it 'must not require a secret' do
    t = Transloadit.new(:key => @key)
    t.must_be_kind_of Transloadit
  end
  
  describe 'when initialized' do
    before do
      @transloadit = Transloadit.new(:key => @key, :secret => @secret)
    end
    
    it 'must allow access to the key' do
      @transloadit.key.must_equal @key
    end
    
    it 'must allow access to the secret' do
      @transloadit.secret.must_equal @secret
    end
    
    it 'must create steps' do
      step = @transloadit.step('/image/resize', :width => 320)

      step.must_be_kind_of Transloadit::Step
      step.robot.  must_equal '/image/resize'
      step.options.must_equal :width => 320
    end
    
    it 'must create assemblies' do                     
      step     = @transloadit.step('')
      assembly = @transloadit.assembly :steps => step
      
      assembly.must_be_kind_of Transloadit::Assembly
      assembly.steps.must_equal [ step ]
    end
  end
end
