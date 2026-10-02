require "rails_helper"

RSpec.describe MatchJobTool do
  let(:use_case) { instance_double(MatchJobUseCase) }
  let(:result) do
    {
      summary: [ { text: "Strong fit.", citations: [ { source: 0, cited_text: "Rails" } ] } ],
      sources: [ { title: "alpha", url: "https://github.com/octo/alpha" } ],
      usage: { input_tokens: 900, output_tokens: 80 }
    }
  end

  before { allow(MatchJobUseCase).to receive(:new).and_return(use_case) }

  it "advertises the name and its single argument" do
    expect(described_class.tool_name).to eq("match_job")
    expect(described_class.input_schema.to_h[:properties].keys).to contain_exactly(:job_description)
  end

  it "records the agent connection and returns the cited summary without the usage" do
    allow(use_case).to receive(:execute).with(job_description: "Rails role").and_return(result)
    response = nil

    expect { response = described_class.call(job_description: "Rails role") }.to change(AgentConnection, :count).by(1)

    expect(AgentConnection.last.tool).to eq("match_job")
    expect(response.to_h[:isError]).to be_falsey
    expect(JSON.parse(response.content.first[:text], symbolize_names: true)).to eq(result.slice(:summary, :sources))
  end

  it "reports job_match.completed with usage, never the job description" do
    allow(use_case).to receive(:execute).and_return(result)

    events = captured_events { described_class.call(job_description: "Secret role at Acme") }

    payload = find_event(events, "job_match.completed")[:payload]
    expect(payload).to include(surface: "mcp", sources: 1, llm_input: 900, llm_output: 80)
    expect(payload[:duration_ms]).to be_a(Integer)
    expect(payload.to_json).not_to include("Acme")
  end

  it "records the connection even when the call is invalid, and answers with an error" do
    allow(use_case).to receive(:execute).and_raise(ValidationError.new(job_description: "can't be blank"))
    response = nil

    events = captured_events do
      expect { response = described_class.call }.to change(AgentConnection, :count).by(1)
    end

    expect(response.to_h[:isError]).to be(true)
    expect(response.content.first[:text]).to eq("can't be blank")
    expect(find_event(events, "job_match.rejected")[:payload]).to eq(severity: "warn", surface: "mcp", reason: "can't be blank")
  end
end
