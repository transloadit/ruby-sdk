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
        response = @assembly.create! open('lib/transloadit/version.rb')
        response.code.must_equal 302
        response.headers[:location].must_match %r{^http://foo.bar/}
      end
    end

    describe 'with additional parameters' do
      include WebMock::API

      before do
        WebMock.reset!
        stub_request(:post, 'api2.transloadit.com/assemblies')
      end

      after do
        WebMock.reset!
      end

      it 'must allow to send a template id along' do
        Transloadit::Assembly.new(
          @transloadit,
          :template_id => 'TEMPLATE_ID'
        ).create!

        assert_requested(:post, 'api2.transloadit.com/assemblies') do |req|
          values = values_from_post_body(req.body)
          MultiJson.load(values['params'])['template_id'].must_equal 'TEMPLATE_ID'
        end
      end

      it 'must allow to send the fields hash' do
        Transloadit::Assembly.new(
          @transloadit,
          :fields => {:tag => 'ninja-cat'}
        ).create!

        assert_requested(:post, 'api2.transloadit.com/assemblies') do |req|
          values = values_from_post_body(req.body)
          values['tag'].must_equal 'ninja-cat'
          MultiJson.load(values['params'])['fields']['tag'].must_equal 'ninja-cat'
        end
      end

      it 'must allow steps through the create! method' do
        Transloadit::Assembly.new(@transloadit).create!(
          { :steps => @transloadit.step('thumbs', '/video/thumbs') }
        )

        assert_requested(:post, 'api2.transloadit.com/assemblies') do |req|
          values = values_from_post_body(req.body)
          MultiJson.load(values['params'])['steps'].must_equal({'thumbs'=>{'robot'=>'/video/thumbs'}})
        end
      end

      it 'must allow steps passed through the create! method override steps previously set' do
        @assembly.create!({ :steps => @transloadit.step('resize', '/image/resize') })

        assert_requested(:post, 'api2.transloadit.com/assemblies') do |req|
          values = values_from_post_body(req.body)
          MultiJson.load(values['params'])['steps'].must_equal({"resize"=>{'robot'=>'/image/resize'}})
        end
      end
    end

    describe 'when using the "submit!" method' do

      it 'must call the create! method with the same parameters' do
        VCR.use_cassette 'submit_assembly' do
          file = open('lib/transloadit/version.rb')
          mocker = MiniTest::Mock.new
          mocker.expect :call, nil, [file]
          @assembly.stub :create!, mocker do
            @assembly.submit!(file)
          end
          mocker.verify
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

  describe 'using assembly API methods' do
    include WebMock::API

    before do
      WebMock.reset!
      @assembly = Transloadit::Assembly.new @transloadit
    end

    describe 'when fetching all assemblies' do

      it 'must perform GET request to /assemblies' do
        stub = stub_request(:get, 'api2.transloadit.com/assemblies?params=%7B%22auth%22:%7B%22key%22:%22%22%7D%7D')
        @assembly.list

        assert_requested(stub)
      end

      it 'must return a list of items' do
        VCR.use_cassette 'fetch_assemblies' do
          response = @assembly.list

          response['items'].must_equal []
          response['count'].must_equal 0
        end
      end
    end

    describe 'when fetching single assembly' do

      it 'must perform GET request to /assemblies/[id]' do
        stub = stub_request(:get, 'api2.transloadit.com/assemblies/76fe5df1c93a0a530f3e583805cf98b4')
        @assembly.get '76fe5df1c93a0a530f3e583805cf98b4'

        assert_requested(stub)
      end

      it 'must get assembly with specified id' do
        VCR.use_cassette 'fetch_assembly_ok' do
          response = @assembly.get '76fe5df1c93a0a530f3e583805cf98b4'
          response['assembly_id'].must_equal '76fe5df1c93a0a530f3e583805cf98b4'
        end
      end
    end

    describe 'when fetching assembly notifications' do

      it 'must perform GET request to /assembly_notifications' do
        stub = stub_request(
          :get,
          'api2.transloadit.com/assembly_notifications?params=%7B%22auth%22:%7B%22key%22:%22%22%7D%7D'
        )
        @assembly.notifications

        assert_requested(stub)
      end

      it 'must return a list of items' do
        VCR.use_cassette 'fetch_assembly_notifications' do
          response = @assembly.notifications

          response['items'].must_equal []
          response['count'].must_equal 0
        end
      end
    end

    describe 'when replaying assembly' do

      it 'must perform POST request to assemblies/[id]/replay' do
        VCR.use_cassette 'replay_assembly' do
          response = @assembly.replay '55c965a063a311e6ba2d379ef10b28f7'

          response['ok'].must_equal 'ASSEMBLY_REPLAYING'
          response['assembly_id'].must_equal 'b8590300650211e6b826d727b2cfd9ce'
        end
      end
    end

    describe 'when replaying assembly notification' do

      it 'must replay notification of sepcified assembly' do
        VCR.use_cassette 'replay_assembly_notification' do
          response = @assembly.replay_notification '2ea5d21063ad11e6bc93e53395ce4e7d'

          response['ok'].must_equal 'ASSEMBLY_NOTIFICATION_REPLAYED'
          response['assembly_id'].must_equal '2ea5d21063ad11e6bc93e53395ce4e7d'
        end
      end
    end
  end
end

def values_from_post_body(body)
  Addressable::URI.parse('?' + URI.decode(body)).query_values
end
