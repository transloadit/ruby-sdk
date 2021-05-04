require "test_helper"

describe Transloadit::ApiModel do
  let(:foo) { "foo" }
  let(:bar) { "bar" }
  let(:transloadit) { Transloadit.new(key: "") }

  let(:api) {
    Transloadit::ApiModel.new(
      transloadit,
      foo: foo,
      bar: bar
    )
  }

  it "must allow initialization" do
    _(Transloadit::ApiModel.new(transloadit))
      .must_be_kind_of Transloadit::ApiModel

    _(Transloadit::Template.new(transloadit))
      .must_be_kind_of Transloadit::Template
  end

  describe "when initialized" do
    it "must store a pointer to the transloadit instance" do
      _(api.transloadit).must_equal transloadit
    end

    it "must remember the options passed" do
      _(api.options).must_equal(
        foo: foo,
        bar: bar
      )
    end

    it "must inspect like a hash" do
      _(api.inspect).must_equal api.to_hash.inspect
    end

    it "must produce Transloadit-compatible hash output" do
      _(api.to_hash).must_equal(
        auth: transloadit.to_hash,
        foo: foo,
        bar: bar
      )
    end

    it "must produce Transloadit-compatible JSON output" do
      _(api.to_json).must_equal MultiJson.dump(api.to_hash)
    end
  end
end
