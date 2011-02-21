require 'test_helper'

describe Transloadit::Request do
  REQUEST_URI = 'http://api2.jane.transloadit.com/assemblies/76fe5df1c93a0a530f3e583805cf98b4'
  
  before do
    # reset the API endpoint between tests
    Transloadit::Request.api Transloadit::Request::API_ENDPOINT
  end
  
  it 'must allow initialization' do
    request = Transloadit::Request.new '/'
    request.must_be_kind_of Transloadit::Request
  end
  
  it 'should locate bored instances' do
    VCR.use_cassette 'fetch_bored' do
      Transloadit::Request.bored!.
        wont_equal Transloadit::Request::API_ENDPOINT.host
    end
  end
  
  describe 'when performing a GET' do
    before do
      @request = Transloadit::Request.new('instances/bored')
    end
    
    it 'should perform a GET against the resource' do
      VCR.use_cassette 'fetch_bored' do
        @request.get['ok'].must_equal 'BORED_INSTANCE_FOUND'
      end
    end
    
    it 'should allow passing query parameters to a GET'
  end
  
  describe 'when performing a POST' do
    it 'should perform a POST against the resource' do
    end
  end
end
