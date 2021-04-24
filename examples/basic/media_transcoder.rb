# frozen_string_literal: true

class MediaTranscoder
  def transloadit_client
    @transloadit ||= Transloadit.new({
                                       key: ENV.fetch('TRANSLOADIT_KEY'),
                                       secret: ENV.fetch('TRANSLOADIT_SECRET')
                                     })
  end
end
