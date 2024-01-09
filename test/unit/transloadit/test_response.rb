require "test_helper"

describe Transloadit::Response do
  request_uri = "https://api2.jane.transloadit.com/assemblies/76fe5df1c93a0a530f3e583805cf98b4"

  it "must allow delegate initialization" do
    response = Transloadit::Response.new("test")
    _(response.class).must_equal Transloadit::Response
  end

  describe "when initialized" do
    before do
      VCR.use_cassette "fetch_assembly_ok" do
        @response = Transloadit::Response.new(
          RestClient::Resource.new(request_uri).get
        )
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
        @response = Transloadit::Response.new(
          RestClient::Resource.new(request_uri).get
        ).extend!(Transloadit::Response::Assembly)
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
        _(@response.send(:__getobj__))
          .wont_be_same_as @response.reload!.send(:__getobj__)

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
        @response = Transloadit::Response.new(
          RestClient::Resource.new(request_uri).get
        ).extend!(Transloadit::Response::Assembly)
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
        @response = Transloadit::Response.new(
          RestClient::Resource.new(request_uri).get
        ).extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal false
      _(@response.uploading?).must_equal true
      _(@response.error?).must_equal false
    end

    it "must allow to check for executing" do
      VCR.use_cassette "fetch_assembly_executing" do
        @response = Transloadit::Response.new(
          RestClient::Resource.new(request_uri).get
        ).extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal false
      _(@response.executing?).must_equal true
      _(@response.error?).must_equal false
    end

    it "must allow to check for replaying" do
      VCR.use_cassette "replay_assembly" do
        @response = Transloadit::Response.new(
          RestClient::Resource.new(
            "https://api2.transloadit.com/assemblies/55c965a063a311e6ba2d379ef10b28f7/replay"
          ).post({})
        ).extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal false
      _(@response.replaying?).must_equal true
      _(@response.error?).must_equal false
    end

    it "must allow to check for aborted" do
      VCR.use_cassette "fetch_assembly_aborted" do
        @response = Transloadit::Response.new(
          RestClient::Resource.new(request_uri).get
        ).extend!(Transloadit::Response::Assembly)
      end

      _(@response.finished?).must_equal true
      _(@response.aborted?).must_equal true
    end

    it "must allow to check for errors" do
      VCR.use_cassette "fetch_assembly_errors" do
        @response = Transloadit::Response.new(
          RestClient::Resource.new(request_uri).get
        ).extend!(Transloadit::Response::Assembly)
      end

      _(@response.error?).must_equal true
      _(@response.finished?).must_equal true
    end
  end
end
