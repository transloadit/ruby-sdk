require 'test_helper'

describe Transloadit::Request do
  before do
    # reset the API endpoint between tests
    Transloadit::Request.api Transloadit::Request::API_ENDPOINT
  end

  it 'must allow initialization' do
    request = Transloadit::Request.new '/'
    request.must_be_kind_of Transloadit::Request
  end

  it 'must locate bored instances' do
    VCR.use_cassette 'fetch_bored' do
      Transloadit::Request.bored!.
        wont_equal Transloadit::Request::API_ENDPOINT.host
    end
  end

  describe 'when performing a GET' do
    before do
      @request = Transloadit::Request.new('instances/bored')
    end

    it 'must inspect to the API URL' do
      @request.inspect.must_equal @request.url.to_s.inspect
    end

    it 'must perform a GET against the resource' do
      VCR.use_cassette 'fetch_bored' do
        @request.get(:params => { :foo => 'bar'})['ok'].
          must_equal 'BORED_INSTANCE_FOUND'
      end
    end

    describe 'with secret' do
      before do
        @request.secret = "tehsupersecrettoken"
      end

      it 'must inspect to the API URL' do
        @request.inspect.must_equal @request.url.to_s.inspect
      end

      it 'must perform a GET against the resource' do
        VCR.use_cassette 'fetch_bored' do
          @request.get(:params => { :foo => 'bar'})['ok'].
              must_equal 'BORED_INSTANCE_FOUND'
        end
      end

    end
  end

  describe 'when performing a POST' do
    before do
      @request = Transloadit::Request.new('assemblies', 'secret')
    end

    it 'must perform a POST against the resource' do
      VCR.use_cassette 'post_assembly' do
        @request.post(:params => {
          :auth  => { :key     => '',
                      :expires => (Time.now + 10).utc.strftime('%Y/%m/%d %H:%M:%S+00:00') },
          :steps => { :encode => { :robot => '/video/encode' } }
        })['ok'].must_equal 'ASSEMBLY_COMPLETED'
      end
    end
  end
end
