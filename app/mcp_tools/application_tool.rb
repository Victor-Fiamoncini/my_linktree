class ApplicationTool < MCP::Tool
  def self.call(server_context: nil, **args)
    RecordAgentConnectionUseCase.new.execute(tool: tool_name)

    text_response(perform(**args).to_json)
  rescue ArgumentError => e
    rejected(e, **args)

    text_response(e.message, error: true)
  end

  def self.perform(**)
    raise NotImplementedError
  end

  def self.rejected(error, **)
    raise error
  end

  def self.text_response(text, error: false)
    MCP::Tool::Response.new([ { type: "text", text: text } ], error: error)
  end
end
