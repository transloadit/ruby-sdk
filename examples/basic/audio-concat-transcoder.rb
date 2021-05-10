class AudioConcatTranscoder < MediaTranscoder
  require "transloadit"
  require_relative "media-transcoder"

  # in this example a file is encoded as an mp3, id3 tags are added, and it is stored in s3
  def transcode!(files)
    concat = transloadit_client.step("concat", "/audio/concat", {
      preset: "mp3",
      use: {
        steps: files.map.each_with_index do |f, i|
          {name: ":original", as: "audio_#{i}", fields: "file_#{i}"}
        end
      },
      result: true
    })

    steps = [concat]

    begin
      store = transloadit_client.step("store", "/s3/store", {
        key: ENV.fetch("S3_ACCESS_KEY"),
        secret: ENV.fetch("S3_SECRET_KEY"),
        bucket: ENV.fetch("S3_BUCKET"),
        bucket_region: ENV.fetch("S3_REGION"),
        use: ["concat"]
      })

      steps.push(store)
    rescue KeyError
      p "s3 config not set. Skipping s3 storage..."
    end

    assembly = transloadit_client.assembly(steps: steps)
    assembly.create!(*open_files(files))
  end

  def open_files(files)
    files.map do |f|
      File.open(f)
    end
  end

  def mp3_metadata
    meta = {publisher: "Transloadit", title: "${file.name}"}
    meta[:album] = "Transloadit Compilation"
    meta[:artist] = "Transloadit"
    meta[:track] = "1/1"
    meta
  end
end
