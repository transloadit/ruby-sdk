require "open-uri"
require_relative "media-transcoder"
require_relative "image-transcoder"
require_relative "audio-transcoder"
require_relative "audio-concat-transcoder"

p "starting image transcoding job..."
p "fetching image from the cat api..."

open("#{__dir__}/assets/cat.jpg") do |f|
  p "starting transcoding job..."
  image_transcoder = ImageTranscoder.new
  response = image_transcoder.transcode!(f)

  # if you are using rails one thing you can do would be to start an ActiveJob process that recursively
  # checks on the status of the assembly until it is finished
  p "checking job status..."
  response.reload_until_finished!

  p response[:message]
  p response[:results]["image"][0]["ssl_url"]
end

p "starting audio transcoding job..."
p "fetching soundbite from nasa..."
p "\n"

open("#{__dir__}/assets/Computers_are_in_Control.flac") do |f|
  p "starting transcoding job..."
  audio_transcoder = AudioTranscoder.new
  response = audio_transcoder.transcode!(f)

  # if you are using rails one thing you can do would be to start an ActiveJob process that recursively
  # checks on the status of the assembly until it is finished
  p "checking job status..."
  response.reload_until_finished!

  p response[:message]
  p response[:results]["mp3"][0]["ssl_url"]
  p "\n"
end

p "starting audio concat transcoding job..."
p "fetching 3 soundbites from nasa..."

files = [
  "#{__dir__}/assets/APU_Shutdown.mp3",
  "#{__dir__}/assets/Go_for_Deploy.mp3",
  "#{__dir__}/assets/Lookin_At_It.mp3"
]

p "starting transcoding job..."
audio_concat_transcoder = AudioConcatTranscoder.new
response = audio_concat_transcoder.transcode!(files)

# if you are using rails one thing you can do would be to start an ActiveJob process that recursively
# checks on the status of the assembly until it is finished
p "checking job status..."
response.reload_until_finished!

p response[:message]
p response[:results]["concat"][0]["ssl_url"]
p "\n"
