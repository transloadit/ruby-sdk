require 'test_helper'

describe Transloadit::Robot do
  it 'must allow initialization' do
    Transloadit::Robot.new('/s3/store').must_be_kind_of Transloadit::Robot
  end
  
  describe 'when initialized' do
    before do
      @type   = '/s3/store'
      @key    = 'aws-access-key-id'
      @secret = 'aws-secret-access-key'
      @bucket = 's3-bucket-name'
      
      @robot = Transloadit::Robot.new '/s3/store',
        :key    => @key,
        :secret => @secret,
        :bucket => @bucket
    end
    
    it 'must generate a name' do
      @robot.name.wont_equal nil
    end
    
    it 'must generate a unique name' do
      @robot.name.wont_equal Transloadit::Robot.new('').name
    end
    
    it 'must generate a name with 32 hex characters' do
      @robot.name.length.must_equal 32
    end
    
    it 'must remember the type' do
      @robot.type.must_equal @type
    end
    
    it 'must remember the parameters' do
      @robot.options.must_equal(
        :key    => @key,
        :secret => @secret,
        :bucket => @bucket
      )
    end
    
    it 'must produce Transloadit-compatible hash output' do
      @robot.to_h.must_equal(
        @robot.name => {
          :robot  => @type,
          :key    => @key,
          :secret => @secret,
          :bucket => @bucket
        }
      )
    end
    
    it 'must produce Transloadit-compatible JSON output' do
      @robot.to_json.must_equal @robot.to_h.to_json
    end
  end
  
  describe 'when using alternative inputs' do
    before do
      @robot = Transloadit::Robot.new '/image/resize'
    end
    
    it 'must allow using the original file as input' do
      @robot.use(:original).must_equal ':original'
      @robot.options[:use].must_equal ':original'
    end
    
    it 'must allow using another robot' do
      input = Transloadit::Robot.new '/video/thumbnail'
      
      @robot.use(input).must_equal [ input.name ]
      @robot.options[:use].must_equal [ input.name ]
    end
    
    it 'must allow using multiple robots' do
      inputs = [
        Transloadit::Robot.new('/video/thumbnail'),
        Transloadit::Robot.new('/image/resize')
      ]
      
      @robot.use(inputs).must_equal inputs.map {|i| i.name }
      @robot.options[:use].must_equal inputs.map {|i| i.name }
    end
    
    it 'must allow using nothing' do
      @robot.use :original
      @robot.use(nil).must_equal nil
      @robot.options.keys.wont_include(:use)
    end
    
    it 'must include the used robots in the hash output' do
      @robot.use(:original).must_equal ':original'
      @robot.to_h[@robot.name][:use].must_equal ':original'
    end
  end
end
