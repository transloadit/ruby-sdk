require 'test_helper'

describe Transloadit::API do
  before do
    @transloadit = Transloadit.new(:key => '')
  end

  it 'must allow initialization' do
    Transloadit::API.new(@transloadit).
      must_be_kind_of Transloadit::API

    Transloadit::Template.new(@transloadit).
      must_be_kind_of Transloadit::Template
  end

  describe 'when initialized' do
    before do
      @foo = 'foo'
      @bar = 'bar'

      @api = Transloadit::API.new @transloadit,
        :foo => @foo,
        :bar => @bar
    end

    it 'must store a pointer to the transloadit instance' do
      @api.transloadit.must_equal @transloadit
    end

    it 'must remember the options passed' do
      @api.options.must_equal(
        :foo => @foo,
        :bar => @bar
      )
    end

    it 'must inspect like a hash' do
      @api.inspect.must_equal @api.to_hash.inspect
    end

    it 'must produce Transloadit-compatible hash output' do
      @api.to_hash.must_equal(
        :auth => @transloadit.to_hash,
        :foo  => @foo,
        :bar  => @bar
      )
    end

    it 'must produce Transloadit-compatible JSON output' do
      @api.to_json.must_equal MultiJson.dump(@api.to_hash)
    end
  end
end
