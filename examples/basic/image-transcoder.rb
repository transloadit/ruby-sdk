class ImageTranscoder < MediaTranscoder
  require 'transloadit'
  require_relative 'media-transcoder'

  # in this example a file is submitted, optimized, and then stored in s3
  def transcode!(file)
    optimize = transloadit_client.step('image', '/image/optimize', {
      progressive: true,
      use: ':original',
      result: true
    })
    store = transloadit_client.step('store', '/s3/store', {
      key: ENV.fetch('S3_ACCESS_KEY'),
      secret: ENV.fetch('S3_SECRET_KEY'),
      bucket: ENV.fetch('S3_BUCKET'),
      bucket_region: ENV.fetch('S3_REGION'),
      use: 'image'
    })
    assembly = transloadit_client.assembly(steps: [optimize, store])
    assembly.submit! open(file)
  end

  def get_status!(assembly_id)
    req = Transloadit::Request.new('/assemblies/' + assembly_id.to_s, ENV.fetch('TRANSLOADIT_SECRET'))
    req.get.extend!(Transloadit::Response::Assembly)
  end
end
