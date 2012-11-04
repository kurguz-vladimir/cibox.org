module OutputHelper

  private

  def shell_stream out
    output_stream << "event: shell_stream\n"
    output_stream << "data: %s\n\n" % out.strip
  end
  
  def crud_stream data
    output_stream << "event: crud_stream\n"
    output_stream << "data: %s\n\n" % data.to_json
  end
  
  def rpc_stream procedure, call = nil
    output_stream << "event: rpc_stream\n"
    output_stream << "data: %s\n\n" % {procedure: procedure, call: call}.to_json
  end
  
end
