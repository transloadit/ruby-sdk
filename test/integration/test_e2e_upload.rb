require "test_helper"
require "webmock"

describe "Transloadit end-to-end upload" do
  before do
    skip "Set RUBY_SDK_E2E=1 to run live upload tests" unless e2e_enabled?

    @key = ENV["TRANSLOADIT_KEY"]
    @secret = ENV["TRANSLOADIT_SECRET"]
    skip "TRANSLOADIT_KEY and TRANSLOADIT_SECRET must be set to run live upload tests" if blank?(@key) || blank?(@secret)

    @fixture_path = File.expand_path("../../chameleon.jpg", __dir__)
    skip "chameleon.jpg fixture missing; run tests from the repository root" unless File.file?(@fixture_path)
  end

  it "uploads and processes the chameleon image" do
    with_live_http do
      transloadit = Transloadit.new(key: @key, secret: @secret)

      resize_step = transloadit.step(
        "resize",
        "/image/resize",
        use: ":original",
        width: 128,
        height: 128,
        resize_strategy: "fit",
        format: "png"
      )

      response = File.open(@fixture_path, "rb") do |upload|
        transloadit.assembly.create!(
          upload,
          wait: true,
          steps: resize_step
        )
      end

      response.reload_until_finished!(tries: 120) unless response.finished?

      _(response.completed?).must_equal true, "Assembly did not complete successfully: #{response.body.inspect}"

      uploads = response["uploads"] || []
      refute_empty uploads, "Expected uploads in the assembly response"

      upload_info = uploads.first
      basename = upload_info["basename"]
      _(basename).must_equal File.basename(@fixture_path, ".*") if basename

      filename = upload_info["name"]
      _(filename).must_equal File.basename(@fixture_path) if filename

      results = (response["results"] || {})["resize"] || []
      refute_empty results, "Expected resize results in assembly response"

      first_result = results.first
      ssl_url = first_result["ssl_url"]
      refute_nil ssl_url, "Missing ssl_url in resize result: #{first_result.inspect}"
      _(ssl_url).must_match(/\Ahttps:\/\//)

      meta = first_result["meta"] || {}
      width = integer_if_present(meta["width"])
      height = integer_if_present(meta["height"])
      refute_nil width, "Missing width metadata: #{meta.inspect}"
      refute_nil height, "Missing height metadata: #{meta.inspect}"
      assert width.positive? && width <= 128, "Unexpected width #{width.inspect}"
      assert height.positive? && height <= 128, "Unexpected height #{height.inspect}"
    end
  end

  private

  def with_live_http
    VCR.turn_off!(ignore_cassettes: true)
    WebMock.allow_net_connect!
    yield
  ensure
    WebMock.disable_net_connect!(allow_localhost: true)
    VCR.turn_on!
  end

  def e2e_enabled?
    flag = ENV["RUBY_SDK_E2E"]
    return false if blank?(flag)

    %w[1 true yes on].include?(flag.to_s.strip.downcase)
  end

  def integer_if_present(value)
    return nil if blank?(value)

    value.to_i
  end

  def blank?(value)
    value.respond_to?(:empty?) ? value.empty? : !value
  end
end
