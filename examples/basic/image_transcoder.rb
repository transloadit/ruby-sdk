# frozen_string_literal: true

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

    steps = [optimize]

    begin
      store = transloadit_client.step('store', '/s3/store', {
                                        key: ENV.fetch('S3_ACCESS_KEY'),
                                        secret: ENV.fetch('S3_SECRET_KEY'),
                                        bucket: ENV.fetch('S3_BUCKET'),
                                        bucket_region: ENV.fetch('S3_REGION'),
                                        use: 'image'
                                      })

      steps.push(store)
    rescue KeyError => e
      p 's3 config not set. Skipping s3 storage...'
    end

    assembly = transloadit_client.assembly(steps: steps)
    assembly.create! open(file)
  end
end
