require 'test_helper'

describe Transloadit::Template do

  it 'must inherit from Transloadit::API class' do
    (Transloadit::Template < Transloadit::API).must_equal true
  end

  describe 'using template API methods' do
    include WebMock::API

    before do
      WebMock.reset!
      @transloadit = Transloadit.new(:key => '')
      @template = Transloadit::Template.new @transloadit
    end

    it 'must allow to create new template' do
      VCR.use_cassette 'create_template' do
        response = @template.create(
          {
            :name => 'foo',
            :template => {'key' => 'value'}
          }
        )
        response['ok'].must_equal 'TEMPLATE_CREATED'
        response['template_name'].must_equal 'foo'
        response['template_content']['key'].must_equal 'value'
      end
    end

    describe 'when fetching all templates' do

      it 'must perform GET request to /templates' do
        stub = stub_request(:get, 'api2.transloadit.com/templates?params=%7B%22auth%22:%7B%22key%22:%22%22%7D%7D')
        @template.list

        assert_requested(stub)
      end

      it 'must return a list of items' do
        VCR.use_cassette 'fetch_templates' do
          response = @template.list

          response['items'].must_equal []
          response['count'].must_equal 0
        end
      end
    end

    describe 'when fetching single template' do

      it 'must perform GET request to /templates/[id]' do
        stub = stub_request(
          :get,
          'api2.transloadit.com/templates/76fe5df1c93a0a530f3e583805cf98b4?params=%7B%22auth%22:%7B%22key%22:%22%22%7D%7D'
        )
        @template.get '76fe5df1c93a0a530f3e583805cf98b4'

        assert_requested(stub)
      end

      it 'must get template with specified id' do
        VCR.use_cassette 'fetch_template' do
          response = @template.get '76fe5df1c93a0a530f3e583805cf98b4'
          response['ok'].must_equal 'TEMPLATE_FOUND'
          response['template_id'].must_equal '76fe5df1c93a0a530f3e583805cf98b4'
        end
      end
    end

    describe 'when updating template' do

      it 'must perform PUT request to templates/[id]' do
        url = 'api2.transloadit.com/templates/76fe5df1c93a0a530f3e583805cf98b4'
        stub = stub_request(:put, url)
        @template.update(
          '76fe5df1c93a0a530f3e583805cf98b4',
          {:name => 'foo', :template => {:key => 'value'}}
        )

        assert_requested(:put, url) do |req|
          values = values_from_post_body(req.body)
          data = MultiJson.load(values['params'])
          data['name'].must_equal 'foo'
          data['template']['key'].must_equal 'value'
        end
      end

      it 'must update template with specified id' do
        VCR.use_cassette 'update_template' do
          response = @template.update '55c965a063a311e6ba2d379ef10b28f7'

          response['ok'].must_equal 'TEMPLATE_UPDATED'
          response['template_id'].must_equal '55c965a063a311e6ba2d379ef10b28f7'
        end
      end
    end

    describe 'when deleting a template' do

      it 'must perform DELETE request to templates/[id]' do
        stub = stub_request(:delete, 'api2.transloadit.com/templates/76fe5df1c93a0a530f3e583805cf98b4')
        @template.delete '76fe5df1c93a0a530f3e583805cf98b4'

        assert_requested(stub)
      end

      it 'must delete specified template templates' do
        VCR.use_cassette 'delete_template' do
          response = @template.delete '55c965a063a311e6ba2d379ef10b28f7'

          response['ok'].must_equal 'TEMPLATE_DELETED'
        end
      end
    end
  end
end
