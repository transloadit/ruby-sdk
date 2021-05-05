require "open-uri"
require_relative "media-transcoder"
require_relative "image-transcoder"
require_relative "audio-transcoder"
require_relative "audio-concat-transcoder"

p "starting image transcoding job..."
p "fetching image from the cat api..."

open("http://thecatapi.com/api/images/get") do |f|
  p "starting transcoding job..."
  image_transcoder = ImageTranscoder.new
  response = image_transcoder.transcode!(f)

  # if you are using rails one thing you can do would be to start an ActiveJob process that recursively
  # checks on the status of the assembly until it is finished
  p "checking job status..."
  response.reload_until_finished!

  p response[:message]
  p response[:results]["image"][0]["url"]
end

p "starting audio transcoding job..."
p "fetching soundbite from nasa..."
p "\n"

open("https://www.nasa.gov/640379main_Computers_are_in_Control.m4r") do |f|
  p "starting transcoding job..."
  audio_transcoder = AudioTranscoder.new
  response = audio_transcoder.transcode!(f)

  # if you are using rails one thing you can do would be to start an ActiveJob process that recursively
  # checks on the status of the assembly until it is finished
  p "checking job status..."
  response.reload_until_finished!

  p response[:message]
  p response[:results]["mp3"][0]["url"]
  p "\n"
end

p "starting audio concat transcoding job..."
p "fetching 3 soundbites from nasa..."

files = [
  "https://www.nasa.gov/mp3/640148main_APU%20Shutdown.mp3",
  "https://www.nasa.gov/mp3/640164main_Go%20for%20Deploy.mp3",
  "https://www.nasa.gov/mp3/640165main_Lookin%20At%20It.mp3",
]

p "starting transcoding job..."
audio_concat_transcoder = AudioConcatTranscoder.new
response = audio_concat_transcoder.transcode!(files)

# if you are using rails one thing you can do would be to start an ActiveJob process that recursively
# checks on the status of the assembly until it is finished
p "checking job status..."
response.reload_until_finished!

p response[:message]
p response[:results]["concat"][0]["url"]
p "\n"
