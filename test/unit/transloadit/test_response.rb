require "test_helper"

describe Transloadit::Response do
  request_uri = "https://api2.jane.transloadit.com/assemblies/76fe5df1c93a0a530f3e583805cf98b4"

  it "must allow initialization" do
    response = Transloadit::Response.new(body: "{}", headers: {}, status: 200)
    _(response.class).must_equal Transloadit::Response
  end

  it "must replace body, headers, and status together" do
    response = Transloadit::Response.new(
      body: '{"ok":"ASSEMBLY_EXECUTING"}',
      headers: {"X-Request-Id" => "old-request"},
      status: 202
    )
    replacement = Transloadit::Response.new(
      body: '{"ok":"ASSEMBLY_COMPLETED"}',
      headers: {"X-Request-Id" => "new-request"},
      status: 200
    )

    _(response.body.fetch("ok")).must_equal "ASSEMBLY_EXECUTING"
    returned = response.replace(replacement)

    _(returned).must_be_same_as response
    _(response["ok"]).must_equal "ASSEMBLY_COMPLETED"
    _(response.headers).must_equal x_request_id: "new-request"
    _(response.code).must_equal 200
    _(response.status).must_equal 200
  end

  it "must parse a successful body only once" do
    response = Transloadit::Response.new(body: '{"ok":"ASSEMBLY_COMPLETED"}', headers: {}, status: 200)
    calls = 0
    parser = MultiJson.method(:load)
    with_singleton_method(MultiJson, :load, proc { |raw|
      calls += 1
      parser.call(raw)
    }) do
      parsed = response.body
      _(response.body).must_be_same_as parsed
      _(response["ok"]).must_equal "ASSEMBLY_COMPLETED"
      _(response.inspect).must_equal parsed.inspect
    end

    _(calls).must_equal 1
  end

  it "must preserve array bodies" do
    response = Transloadit::Response.new(body: '[{"assembly_id":"assembly-id"}]', headers: {}, status: 200)

    _(response.body).must_equal [{"assembly_id" => "assembly-id"}]
  end

  it "must memoize JSON null and false without changing their values" do
    null_response = Transloadit::Response.new(body: "null", headers: {}, status: 200)
    false_response = Transloadit::Response.new(body: "false", headers: {}, status: 200)
    assert_nil null_response.body
    _(false_response.body).must_equal false

    with_singleton_method(MultiJson, :load, proc { |_raw| raise "Body was parsed again" }) do
      assert_nil null_response.body
      _(false_response.body).must_equal false
    end
  end

  it "must expose invalid-response diagnostics without including the body in the message" do
    raw_body = "<html>Proxy error: sensitive upstream diagnostics</html>"
    response = Transloadit::Response.new(body: raw_body, headers: {}, status: 502)

    error = assert_raises(Transloadit::Exception::InvalidResponse) { response.body }

    _(error.status).must_equal 502
    _(error.raw_body).must_equal raw_body
    _(error.cause).must_be_kind_of MultiJson::ParseError
    _(error.message).must_equal "Transloadit returned invalid JSON (HTTP 502)"
  end

  it "must wrap parse failures raised through attribute access" do
    response = Transloadit::Response.new(body: "", headers: {}, status: 503)

    error = assert_raises(Transloadit::Exception::InvalidResponse) { response["ok"] }
    _(error.status).must_equal 503
  end

  it "must reject whitespace-only bodies" do
    response = Transloadit::Response.new(body: " \n\t", headers: {}, status: 502)

    assert_raises(Transloadit::Exception::InvalidResponse) { response.body }
  end

  it "must discard a parsed body when a replacement contains invalid JSON" do
    response = Transloadit::Response.new(body: '{"ok":"ASSEMBLY_EXECUTING"}', headers: {}, status: 200)
    _(response.body.fetch("ok")).must_equal "ASSEMBLY_EXECUTING"
    replacement = Transloadit::Response.new(body: "upstream failure", headers: {}, status: 502)

    response.replace(replacement)
    error = assert_raises(Transloadit::Exception::InvalidResponse) { response.body }
    _(error.status).must_equal 502

    response.replace(Transloadit::Response.new(body: '{"ok":"ASSEMBLY_COMPLETED"}', headers: {}, status: 200))
    _(response["ok"]).must_equal "ASSEMBLY_COMPLETED"
  end

  describe "when initialized" do
    before do
      VCR.use_cassette "fetch_assembly_ok" do
        @response = Transloadit::Request.new(request_uri).get
      end
    end

    it "must parse the body" do
      _(@response.body).must_be_kind_of Hash
    end

    it "must allow access to body attributes" do
      %w[ok message assembly_id assembly_ssl_url].each do |attribute|
        _(@response[attribute]).must_equal @response.body[attribute]
      end
    end

    it "must allow access to body attributes as symbols" do
      [:ok, :message, :assembly_id, :assembly_ssl_url].each do |attribute|
        _(@response[attribute]).must_equal @response.body[attribute.to_s]
      end
    end

    it "must inspect as the body" do
      _(@response.inspect).must_equal @response.body.inspect
    end
  end

  describe "when extended as an assembly" do
    before do
      VCR.use_cassette "fetch_assembly_ok" do
        @response = Transloadit::Request.new(request_uri).get.extend!(Transloadit::Response::Assembly)
      end
    end

    it "must allow checking for completion" do
      _(@response.completed?).must_equal true
      _(@response.finished?).must_equal true
      _(@response.error?).must_equal false
    end

    # TODO: can this be tested better?
    it "must allow reloading the assembly" do
      VCR.use_cassette "fetch_assembly_ok", allow_playback_repeats: true do
        _(@response.object_id)
          .must_equal @response.reload!.object_id
      end
    end

    it "must allow canceling" do
      VCR.use_cassette "cancel_assembly" do
        @response.cancel!

        _(@response.completed?).must_equal false
        _(@response["ok"]).must_equal "ASSEMBLY_CANCELED"
        _(@response.canceled?).must_equal true
        _(@response.finished?).must_equal true
      end
    end
  end

  describe "long-running assembly" do
    before do
      VCR.use_cassette "fetch_assembly_executing" do
        @response = Transloadit::Request.new(request_uri).get.extend!(Transloadit::Response::Assembly)
      end
    end

    it "must allow reloading until finished" do
      _(@response.finished?).must_equal false

      VCR.use_cassette "fetch_assembly_ok" do
        VCR.use_cassette "fetch_assembly_executing" do
          @response.reload_until_finished!
        end
      end

      _(@response.finished?).must_equal true
    end

    it "must raise exception if reload until finished tries exceeded" do
      assert_raises Transloadit::Exception::ReloadLimitReached do
        VCR.use_cassette "fetch_assembly_executing", allow_playback_repeats: true do
          @response.reload_until_finished! tries: 1
        end
      end
    end
  end

  describe "statuses" do
    it "must allow checking for upload" do
      VCR.use_cassette "fetch_assembly_uploading" do
        @response = Transloadit::Request.new(request_uri).get.extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal false
      _(@response.uploading?).must_equal true
      _(@response.error?).must_equal false
    end

    it "must allow to check for executing" do
      VCR.use_cassette "fetch_assembly_executing" do
        @response = Transloadit::Request.new(request_uri).get.extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal false
      _(@response.executing?).must_equal true
      _(@response.error?).must_equal false
    end

    it "must allow to check for replaying" do
      VCR.use_cassette "replay_assembly" do
        @response = Transloadit::Request.new(
          "https://api2.transloadit.com/assemblies/55c965a063a311e6ba2d379ef10b28f7/replay"
        ).post.extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal false
      _(@response.replaying?).must_equal true
      _(@response.error?).must_equal false
    end

    it "must allow to check for aborted" do
      VCR.use_cassette "fetch_assembly_aborted" do
        @response = Transloadit::Request.new(request_uri).get.extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal true
      _(@response.aborted?).must_equal true
    end

    it "must allow to check for errors" do
      VCR.use_cassette "fetch_assembly_errors" do
        @response = Transloadit::Request.new(request_uri).get.extend!(Transloadit::Response::Assembly)
      end

      _(@response.error?).must_equal true
      _(@response.finished?).must_equal true
    end
  end
end
