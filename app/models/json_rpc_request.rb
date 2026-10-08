class JsonRpcRequest
  def initialize(request)
    @request = request
  end

  def method_name
    payload["method"]
  end

  def tool
    params["name"]
  end

  def arguments
    hash_or_empty(params["arguments"])
  end

  def tool_call?(name)
    method_name == "tools/call" && tool == name
  end

  private

  def params
    hash_or_empty(payload["params"])
  end

  def hash_or_empty(value)
    value.is_a?(Hash) ? value : {}
  end

  def payload
    @payload ||= parse_body
  end

  def parse_body
    return {} unless @request.post?

    hash_or_empty(JSON.parse(@request.body.read))
  rescue JSON::ParserError, TypeError
    {}
  ensure
    @request.body&.rewind
  end
end
