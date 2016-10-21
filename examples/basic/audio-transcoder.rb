class AudioTranscoder < MediaTranscoder
  require 'transloadit'
  require './media-transcoder'

  # in this example a file is encoded as an mp3, id3 tags are added, and it is stored in s3
  def transcode!(file)
    encode_mp3 = transloadit_client.step('mp3_encode', '/audio/encode', {
      use: ':original',
      preset: 'mp3',
      ffmpeg_stack: 'v2.2.3',
      result: true
    })
    write_metadata = transloadit_client.step('mp3', '/meta/write', {
      use: 'mp3_encode',
      ffmpeg_stack: 'v2.2.3',
      result: true,
      data_to_write: mp3_metadata
    })
    store = transloadit_client.step('store', '/s3/store', {
      key: ENV.fetch('S3_ACCESS_KEY'),
      secret: ENV.fetch('S3_SECRET_KEY'),
      bucket: ENV.fetch('S3_BUCKET'),
      bucket_region: ENV.fetch('S3_REGION'),
      use: ['mp3']
    })
    assembly = transloadit_client.assembly(steps: [encode_mp3, write_metadata, store])
    assembly.submit! open(file)
  end

  def mp3_metadata
    meta = { publisher: 'Transloadit', title: '${file.name}' }
    meta[:album] = 'Transloadit Compilation'
    meta[:artist] = 'Transloadit'
    meta[:track] = '1/1'
    meta
  end
end