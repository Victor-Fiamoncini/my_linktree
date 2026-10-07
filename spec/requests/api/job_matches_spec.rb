require "rails_helper"

RSpec.describe "Api::JobMatches", type: :request do
  let(:json_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }
  let(:use_case) { instance_double(MatchJobUseCase) }
  let(:result) do
    {
      summary: [ { text: "Strong fit.", citations: [ { source: 0, cited_text: "Rails" } ] } ],
      sources: [ { title: "alpha", url: "https://github.com/octo/alpha" } ],
      usage: { input_tokens: 900, output_tokens: 80 }
    }
  end

  before { allow(MatchJobUseCase).to receive(:new).and_return(use_case) }

  def post_job_match(job_description, locale: "en", ip: nil)
    headers = ip ? json_headers.merge("CF-Connecting-IP" => ip) : json_headers
    post "/api/job_match", params: { job_description: job_description, locale: locale }.to_json, headers: headers
  end

  it "returns the summary as plain prose, without citations, sources or usage" do
    result[:summary] << { text: "\n\nSolid APIs.", citations: [] }
    allow(use_case).to receive(:execute).with(job_description: "Rails role").and_return(result)

    post_job_match("Rails role")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("summary" => "Strong fit.\n\nSolid APIs.")
  end

  it "reports job_match.completed without the job description" do
    allow(use_case).to receive(:execute).and_return(result)

    events = captured_events { post_job_match("Secret role at Acme") }

    payload = find_event(events, "job_match.completed")[:payload]
    expect(payload).to include(surface: "web", sources: 1, llm_input: 900, llm_output: 80)
    expect(payload.to_json).not_to include("Acme")
  end

  it "returns field errors in the request's locale" do
    allow(use_case).to receive(:execute) { raise ValidationError.new(job_description: I18n.t("job_matches.errors.blank")) }

    events = captured_events { post_job_match("", locale: "pt-BR") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq(
      "message" => I18n.t("job_matches.validation_failed", locale: :"pt-BR"),
      "errors" => { "job_description" => I18n.t("job_matches.errors.blank", locale: :"pt-BR") }
    )
    expect(find_event(events, "job_match.rejected")[:payload]).to eq(severity: "warn", surface: "web", reason: "job_description")
  end

  it "answers a refusal with a generic 422 rather than a field error" do
    allow(use_case).to receive(:execute).and_raise(ArgumentError, "Request declined")

    events = captured_events { post_job_match("Something") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq("message" => I18n.t("job_matches.declined"))
    expect(find_event(events, "job_match.rejected")[:payload]).to include(reason: "Request declined")
  end

  it "reports job_match.error and renders a handled 500 when a provider fails" do
    allow(use_case).to receive(:execute).and_raise(OpenaiEmbedder::Error, "OpenAI embeddings request failed with HTTP 503")

    events = captured_events { post_job_match("Rails role") }

    expect(response).to have_http_status(:internal_server_error)
    expect(response.parsed_body).to eq("message" => I18n.t("job_matches.internal_error"))
    expect(find_event(events, "job_match.error")[:payload]).to include(severity: "error", error_class: "OpenaiEmbedder::Error")
  end

  it "still reports job_match.error when the exception carries no backtrace" do
    error = OpenaiClient::Error.new("boom")
    allow(error).to receive(:backtrace).and_return(nil)
    allow(use_case).to receive(:execute).and_raise(error)

    events = captured_events { post_job_match("Rails role") }

    expect(response).to have_http_status(:internal_server_error)
    expect(find_event(events, "job_match.error")[:payload][:backtrace]).to be_nil
  end

  it "rate limits after 3 requests from the same IP" do
    allow(use_case).to receive(:execute).and_return(result)
    3.times { post_job_match("Rails role") }

    events = captured_events { post_job_match("Rails role") }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body).to eq("message" => I18n.t("job_matches.too_many_requests"))
    expect(find_event(events, "job_match.rate_limited")[:payload]).to eq(severity: "warn")
  end

  describe "daily limits" do
    before { allow(use_case).to receive(:execute).and_return(result) }

    it "caps one IP at 10 requests a day, even when it stays under the burst limit" do
      travel_to Time.zone.parse("2026-09-28 09:00") do
        10.times do |index|
          travel 11.minutes if index.positive? && (index % 3).zero?
          post_job_match("Rails role", ip: "1.1.1.1")
          expect(response).to have_http_status(:ok)
        end

        travel 11.minutes
        post_job_match("Rails role", ip: "1.1.1.1")
        expect(response).to have_http_status(:too_many_requests)
        expect(response.parsed_body).to eq("message" => I18n.t("job_matches.too_many_requests"))

        post_job_match("Rails role", ip: "2.2.2.2")
        expect(response).to have_http_status(:ok)
      end
    end

    it "caps everyone at 100 requests a day, with its own message and an error event" do
      100.times do |index|
        post_job_match("Rails role", ip: "10.0.#{index / 250}.#{index % 250}")
        expect(response).to have_http_status(:ok)
      end

      events = captured_events { post_job_match("Rails role", ip: "192.168.0.1", locale: "pt-BR") }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body).to eq("message" => I18n.t("job_matches.budget_exhausted", locale: :"pt-BR"))
      expect(find_event(events, "job_match.budget_exhausted")[:payload]).to eq(severity: "error", surface: "web")
      expect(use_case).to have_received(:execute).exactly(100).times
    end

    # Declaration order is the guarantee: a request the per-IP limiters reject never reaches the
    # global limiter, so one abusive IP can't exhaust the budget for everyone else.
    it "doesn't count requests rejected per IP against the global budget" do
      5.times { post_job_match("Rails role", ip: "3.3.3.3") }

      expect(Rails.cache.read("rate-limit:job_match:global:all", raw: true).to_i).to eq(3)
    end

    it "leaves the global budget alone for submissions that fail validation" do
      allow(use_case).to receive(:execute).and_raise(ValidationError.new(job_description: "invalid"))

      post_job_match("   ", ip: "6.6.6.6")
      post_job_match("x" * (MatchJobUseCase::MAX_LENGTH + 1), ip: "6.6.6.6")

      expect(response).to have_http_status(:unprocessable_content)
      expect(Rails.cache.read("rate-limit:job_match:global:all", raw: true)).to be_nil
    end

    it "shares the global budget with MCP match_job calls" do
      post_job_match("Rails role", ip: "4.4.4.4")
      post "/api/mcp",
        params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "match_job", arguments: { job_description: "Rails role" } } }.to_json,
        headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream", "CF-Connecting-IP" => "5.5.5.5" }

      expect(response).to have_http_status(:ok)
      expect(Rails.cache.read("rate-limit:job_match:global:all", raw: true).to_i).to eq(2)
    end
  end

  it "reports job_match.csrf_rejected when the token is missing" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    events = captured_events { post_job_match("Rails role") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq("message" => I18n.t("job_matches.invalid_authenticity_token"))
    expect(find_event(events, "job_match.csrf_rejected")[:payload]).to eq(severity: "warn")
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
