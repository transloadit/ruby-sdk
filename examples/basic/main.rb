require_relative "media-transcoder"
require_relative "image-transcoder"
require_relative "audio-transcoder"
require_relative "audio-concat-transcoder"

puts "starting image transcoding job..."

File.open("#{__dir__}/assets/cat.jpg") do |f|
  image_transcoder = ImageTranscoder.new
  response = image_transcoder.transcode!(f)

  # if you are using rails one thing you can do would be to start an ActiveJob process that recursively
  # checks on the status of the assembly until it is finished
  puts "checking job status..."
  response.reload_until_finished!

  puts response[:message]
  puts response[:results]["image"][0]["ssl_url"]
  puts "\n"
end

puts "starting audio transcoding job..."

File.open("#{__dir__}/assets/Computers_are_in_Control.flac") do |f|
  audio_transcoder = AudioTranscoder.new
  response = audio_transcoder.transcode!(f)

  # if you are using rails one thing you can do would be to start an ActiveJob process that recursively
  # checks on the status of the assembly until it is finished
  puts "checking job status..."
  response.reload_until_finished!

  puts response[:message]
  puts response[:results]["mp3"][0]["ssl_url"]
  puts "\n"
end

puts "starting audio concat transcoding job..."

files = [
  "#{__dir__}/assets/APU_Shutdown.mp3",
  "#{__dir__}/assets/Go_for_Deploy.mp3",
  "#{__dir__}/assets/Lookin_At_It.mp3"
]

audio_concat_transcoder = AudioConcatTranscoder.new
response = audio_concat_transcoder.transcode!(files)

# if you are using rails one thing you can do would be to start an ActiveJob process that recursively
# checks on the status of the assembly until it is finished
puts "checking job status..."
response.reload_until_finished!

puts response[:message]
puts response[:results]["concat"][0]["ssl_url"]
puts "\n"
