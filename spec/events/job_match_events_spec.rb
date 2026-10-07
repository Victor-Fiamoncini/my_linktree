require "rails_helper"

RSpec.describe JobMatchEvents do
  let(:result) { { summary: [], sources: [ { title: "alpha" }, { title: "beta" } ], usage: { input_tokens: 900, output_tokens: 80 } } }

  it "returns the block's result" do
    expect(described_class.completed(surface: "web") { result }).to eq(result)
  end

  it "reports job_match.completed with the surface, source count, usage and duration" do
    events = captured_events { described_class.completed(surface: "mcp") { result } }

    payload = find_event(events, "job_match.completed")[:payload]
    expect(payload).to include(surface: "mcp", sources: 2, llm_input: 900, llm_output: 80)
    expect(payload[:duration_ms]).to be_a(Integer)
  end

  it "reports nothing when the block raises" do
    events = captured_events do
      expect { described_class.completed(surface: "web") { raise ArgumentError } }.to raise_error(ArgumentError)
    end

    expect(events.map { |event| event[:name] }).not_to include("job_match.completed")
  end
end
