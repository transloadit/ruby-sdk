require "test_helper"

describe Transloadit do
  before do
    @key = "a"
    @secret = "b"
    @duration = 10
    @max_size = 100
  end

  it "must allow initialization" do
    t = Transloadit.new(key: @key, secret: @secret)
    _(t).must_be_kind_of Transloadit
  end

  it "must not be initialized with no arguments" do
    _(lambda { Transloadit.new }).must_raise ArgumentError
  end

  it "must require a key" do
    _(lambda { Transloadit.new(secret: @secret) }).must_raise ArgumentError
  end

  it "must not require a secret" do
    t = Transloadit.new(key: @key)
    _(t).must_be_kind_of Transloadit
  end

  it "must provide a default duration" do
    _(Transloadit.new(key: @key).duration).wont_be_nil
  end

  describe "when initialized" do
    before do
      @transloadit = Transloadit.new(
        key: @key,
        secret: @secret,
        duration: @duration,
        max_size: @max_size
      )
    end

    it "must allow access to the key" do
      _(@transloadit.key).must_equal @key
    end

    it "must allow access to the secret" do
      _(@transloadit.secret).must_equal @secret
    end

    it "must allow access to the duration" do
      _(@transloadit.duration).must_equal @duration
    end

    it "must allow access to the max_size" do
      _(@transloadit.max_size).must_equal @max_size
    end

    it "must create steps" do
      step = @transloadit.step("resize", "/image/resize", width: 320)

      _(step).must_be_kind_of Transloadit::Step
      _(step.name).must_equal "resize"
      _(step.robot).must_equal "/image/resize"
      _(step.options).must_equal width: 320
    end

    it "must create assembly api instances" do
      step = @transloadit.step(nil, nil)
      assembly = @transloadit.assembly steps: step

      _(assembly).must_be_kind_of Transloadit::Assembly
      _(assembly.steps).must_equal step.to_hash
    end

    it "must create assemblies with multiple steps" do
      steps = [
        @transloadit.step("step1", nil),
        @transloadit.step("step2", nil)
      ]

      assembly = @transloadit.assembly steps: steps
      _(assembly.steps).must_equal steps.inject({}) { |h, s| h.merge s }
    end

    it "must get user billing report" do
      VCR.use_cassette "fetch_billing" do
        bill = Transloadit.new(key: "").bill(9, 2016)
        _(bill["ok"]).must_equal "BILL_FOUND"
        _(bill["invoice_id"]).must_equal "76fe5df1c93a0a530f3e583805cf98b4"
      end
    end

    it "must create template api instances" do
      template = @transloadit.template
      _(template).must_be_kind_of Transloadit::Template
    end

    it "must inspect like a hash" do
      _(@transloadit.inspect).must_equal @transloadit.to_hash.inspect
    end

    it "must produce Transloadit-compatible hash output" do
      _(@transloadit.to_hash[:key]).must_equal @key
      _(@transloadit.to_hash[:max_size]).must_equal @max_size
      _(@transloadit.to_hash[:expires])
        .must_match %r{\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\+00:00}
    end

    it "must produce Transloadit-compatible JSON output" do
      _(@transloadit.to_json).must_equal MultiJson.dump(@transloadit.to_hash)
    end
  end

  describe "with no secret" do
    before do
      @transloadit = Transloadit.new(key: @key)
    end

    it "must not include a secret in its hash output" do
      _(@transloadit.to_hash.keys).wont_include :secret
    end

    it "must not include a secret in its JSON output" do
      _(@transloadit.to_json).must_equal MultiJson.dump(@transloadit.to_hash)
    end
  end
end
