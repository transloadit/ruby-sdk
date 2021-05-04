require "test_helper"

describe Transloadit::Request do
  it "must allow initialization" do
    request = Transloadit::Request.new "/"
    request.must_be_kind_of Transloadit::Request
  end

  describe "when performing a GET" do
    before do
      @request = Transloadit::Request.new "/"
    end

    it "must inspect to the API URL" do
      @request.inspect.must_equal @request.url.to_s.inspect
    end

    it "must perform a GET against the resource" do
      VCR.use_cassette "fetch_root" do
        @request.get(params: {foo: "bar"})["ok"]
          .must_equal "SERVER_ROOT"
      end
    end

    describe "with secret" do
      before do
        @request.secret = "tehsupersecrettoken"
      end

      it "must inspect to the API URL" do
        @request.inspect.must_equal @request.url.to_s.inspect
      end

      it "must perform a GET against the resource" do
        VCR.use_cassette "fetch_root" do
          @request.get(params: {foo: "bar"})["ok"]
            .must_equal "SERVER_ROOT"
        end
      end
    end
  end

  describe "when performing a POST" do
    it "must perform a POST against the resource" do
      @request = Transloadit::Request.new("assemblies", "secret")

      VCR.use_cassette "post_assembly" do
        @request.post(params: {
          auth: {key: "",
                 expires: (Time.now + 10).utc.strftime("%Y/%m/%d %H:%M:%S+00:00")},
          steps: {encode: {robot: "/video/encode"}}
        })["ok"].must_equal "ASSEMBLY_COMPLETED"
      end
    end
  end

  describe "when performing a PUT" do
    it "must perform a PUT against the resource" do
      @request = Transloadit::Request.new("templates/55c965a063a311e6ba2d379ef10b28f7", "secret")
      VCR.use_cassette "update_template" do
        @request.put(params: {
          name: "foo",
          template: {key: "value"}
        })["ok"].must_equal "TEMPLATE_UPDATED"
      end
    end
  end

  describe "when performing a DELETE" do
    it "must perform a DELETE against the resource" do
      @request = Transloadit::Request.new("templates/55c965a063a311e6ba2d379ef10b28f7", "secret")

      VCR.use_cassette "delete_template" do
        @request.delete["ok"].must_equal "TEMPLATE_DELETED"
      end
    end
  end
end
