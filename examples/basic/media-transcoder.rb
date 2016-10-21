class MediaTranscoder
  def transloadit_client
    unless @transloadit
      @transloadit = Transloadit.new({
        key: ENV.fetch('TRANSLOADIT_KEY'),
        secret: ENV.fetch('TRANSLOADIT_SECRET')
      })
    end
    @transloadit
  end

  def get_status!(assembly_id)
    req = Transloadit::Request.new('/assemblies/' + assembly_id.to_s, ENV.fetch('TRANSLOADIT_SECRET'))
    req.get.extend!(Transloadit::Response::Assembly)
  end
end