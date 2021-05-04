require "test_helper"

describe Transloadit::Step do
  it "must allow initialization" do
    _(Transloadit::Step.new("store", "/s3/store"))
      .must_be_kind_of Transloadit::Step
  end

  describe "when initialized" do
    before do
      @name = "store"
      @robot = "/s3/store"
      @key = "aws-access-key-id"
      @secret = "aws-secret-access-key"
      @bucket = "s3-bucket-name"

      @step = Transloadit::Step.new @name, @robot,
        key: @key,
        secret: @secret,
        bucket: @bucket
    end

    it "should use the name given" do
      _(@step.name).must_equal @name
    end

    it "must remember the type" do
      _(@step.robot).must_equal @robot
    end

    it "must remember the parameters" do
      _(@step.options).must_equal(
        key: @key,
        secret: @secret,
        bucket: @bucket
      )
    end

    it "must inspect like a hash" do
      _(@step.inspect).must_equal @step.to_hash[@step.name].inspect
    end

    it "must produce Transloadit-compatible hash output" do
      _(@step.to_hash).must_equal(
        @step.name => {
          robot: @robot,
          key: @key,
          secret: @secret,
          bucket: @bucket
        }
      )
    end

    it "must produce Transloadit-compatible JSON output" do
      _(@step.to_json).must_equal MultiJson.dump(@step.to_hash)
    end
  end

  describe "when using alternative inputs" do
    before do
      @step = Transloadit::Step.new "resize", "/image/resize"
    end

    it "must allow using the original file as input" do
      _(@step.use(:original)).must_equal ":original"
      _(@step.options[:use]).must_equal ":original"
    end

    it "must allow using another step" do
      input = Transloadit::Step.new "thumbnail", "/video/thumbnail"

      _(@step.use(input)).must_equal [input.name]
      _(@step.options[:use]).must_equal [input.name]
    end

    it "must allow using multiple steps" do
      inputs = [
        Transloadit::Step.new("thumbnail", "/video/thumbnail"),
        Transloadit::Step.new("resize", "/image/resize")
      ]

      _(@step.use(inputs)).must_equal inputs.map { |i| i.name }
      _(@step.options[:use]).must_equal inputs.map { |i| i.name }
    end

    it "must allow using nothing" do
      @step.use :original
      assert_nil @step.use(nil)
      _(@step.options.keys).wont_include(:use)
    end

    it "must include the used steps in the hash output" do
      _(@step.use(:original)).must_equal ":original"
      _(@step.to_hash[@step.name][:use]).must_equal ":original"
    end
  end
end
