require 'test_helper'

describe Transloadit::Assembly do
  before do
    @transloadit = Transloadit.new(:key => '')
  end

  it 'must allow initialization' do
    Transloadit::Assembly.new(@transloadit).
      must_be_kind_of Transloadit::Assembly
  end

  describe 'when initialized' do
    before do
      @step     = @transloadit.step 'thumbs', '/video/thumbs'
      @redirect = 'http://foo.bar/'

      @assembly = Transloadit::Assembly.new @transloadit,
        :steps        => @step,
        :redirect_url => @redirect
    end

    it 'must store a pointer to the transloadit instance' do
      @assembly.transloadit.must_equal @transloadit
    end

    it 'must remember the options passed' do
      @assembly.options.must_equal(
        :steps        => @step,
        :redirect_url => @redirect
      )
    end

    it 'must wrap its step in a hash' do
      @assembly.steps.must_equal @step.to_hash
    end

    it 'must not wrap a nil step' do
      @assembly.options[:steps] = nil
      @assembly.steps.must_equal nil
    end

    it 'must not wrap a hash step' do
      @assembly.options[:steps] = { :foo => 1 }
      @assembly.steps.must_equal :foo => 1
    end

    it 'must inspect like a hash' do
      @assembly.inspect.must_equal @assembly.to_hash.inspect
    end

    it 'must produce Transloadit-compatible hash output' do
      @assembly.to_hash.must_equal(
        :auth         => @transloadit.to_hash,
        :steps        => @assembly.steps,
        :redirect_url => @redirect
      )
    end

    it 'must produce Transloadit-compatible JSON output' do
      @assembly.to_json.must_equal MultiJson.dump(@assembly.to_hash)
    end

    it 'must submit files for upload' do
      VCR.use_cassette 'submit_assembly' do
        response = @assembly.submit! open('lib/transloadit/version.rb')
        response.code.must_equal 302
        response.headers[:location].must_match %r{^http://foo.bar/}
      end
    end

    describe 'with additional parameters' do
      include WebMock::API

      before do
        stub_request(:post, 'jane.transloadit.com/assemblies')
      end

      after do
        WebMock.reset!
      end

      it 'must allow to send a template id along' do
        VCR.use_cassette 'fetch_bored' do
          Transloadit::Assembly.new(
            @transloadit,
            :template_id => 'TEMPLATE_ID'
          ).submit!

          assert_requested(:post, 'jane.transloadit.com/assemblies') do |req|
            values = values_from_post_body(req.body)
            MultiJson.load(values['params'])['template_id'].must_equal 'TEMPLATE_ID'
          end
        end
      end

      it 'must allow to send the fields hash' do
        VCR.use_cassette 'fetch_bored' do
          Transloadit::Assembly.new(
            @transloadit,
            :fields => {:tag => 'ninja-cat'}
          ).submit!

          assert_requested(:post, 'jane.transloadit.com/assemblies') do |req|
            values = values_from_post_body(req.body)
            values['tag'].must_equal 'ninja-cat'
            MultiJson.load(values['params'])['fields'].must_equal 'ninja-cat'
          end
        end
      end
    end
  end

  describe 'with multiple steps' do
    before do
      @encode = @transloadit.step 'encode', '/video/encode'
      @thumbs = @transloadit.step 'thumbs', '/video/thumbs'

      @assembly = Transloadit::Assembly.new @transloadit,
        :steps => [ @encode, @thumbs ]
    end

    it 'must wrap its steps into one hash' do
      @assembly.to_hash[:steps].keys.must_include @encode.name
      @assembly.to_hash[:steps].keys.must_include @thumbs.name
    end
  end
end

def values_from_post_body(body)
  Addressable::URI.parse('?' + URI.decode(body)).query_values
end
