module OutputHelper

  private

  def shell_stream out
    output_stream.event 'shell_stream'
    output_stream.data out
  end
  
  def crud_stream data
    output_stream.event 'crud_stream'
    output_stream.data data.to_json
  end
  
  def rpc_stream procedure, call = nil
    output_stream.event 'rpc_stream'
    output_stream.data({procedure: procedure, call: call}.to_json)
  end
  
end
