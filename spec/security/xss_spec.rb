require "rails_helper"

XSS_PAYLOADS = [
  %(<script>window.pwned = "script"</script>),
  %(<img src=x onerror="window.pwned = 'img'">),
  %("><svg onload="window.pwned = 'svg'">)
].freeze

# Model output is attacker-steerable (see prompt_injection_spec.rb), so it has to reach the page
# as text even when it's hostile markup.
RSpec.describe "XSS in the job match result", type: :system do
  let(:use_case) { instance_double(MatchJobUseCase) }

  before do
    allow(MatchJobUseCase).to receive(:new).and_return(use_case)
    visit root_path(locale: "en")
  end

  XSS_PAYLOADS.each do |payload|
    it "shows #{payload[0, 12].inspect}... as text without running it" do
      allow(use_case).to receive(:execute).and_return(
        summary: [ { text: payload, citations: [] } ], sources: [], usage: { input_tokens: 1, output_tokens: 1 }
      )

      fill_in "job_description", with: payload
      click_button "Check the fit"

      expect(page).to have_content(payload)
      expect(page.evaluate_script("window.pwned")).to be_nil
      expect(page).to have_no_css("[data-job-match-target='summary'] *")
    end
  end
end

# The 404 page echoes the requested path into the body and the <head>.
RSpec.describe "XSS in the reflected 404 path", type: :request do
  around do |example|
    env_config = Rails.application.env_config
    original = env_config.slice("action_dispatch.show_detailed_exceptions", "action_dispatch.show_exceptions")
    env_config.merge!("action_dispatch.show_detailed_exceptions" => false, "action_dispatch.show_exceptions" => :all)
    example.run
  ensure
    env_config.merge!(original)
  end

  XSS_PAYLOADS.each do |payload|
    it "escapes #{payload[0, 12].inspect}... in the path" do
      # A browser percent-encodes these, but a raw client like curl doesn't, so inject the raw path.
      get "/en/x", env: { "PATH_INFO" => "/en/#{payload}" }

      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:not_found)
      expect(document.at("main").text).to include("/en/#{payload}")
      expect(document.css("script:not([type='application/ld+json']):not([type='importmap']):not([type='module'])").map(&:text).join).not_to include("pwned")
      expect(document.css("img[onerror], svg[onload]")).to be_empty
      expect(document.css("link[rel='canonical']").sole["href"]).to start_with("#{SeoConfig::SITE_URL}/en/")
    end
  end
end
