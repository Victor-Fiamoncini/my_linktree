require "rails_helper"

RSpec.describe "Telemetry feed", type: :system do
  # Cuprite drives a real browser talking to a real Puma thread over its own Postgres connection,
  # which can't see rows created on the example's own transactional-fixture connection until
  # commit — a commit transactional fixtures never do. Disable them here so a mid-test
  # `AgentConnection.create!` is actually visible to the controller's next fetch.
  self.use_transactional_tests = false

  after { AgentConnection.delete_all }

  it "keeps the reader's scroll position when a new entry arrives from a poll" do
    20.times { |i| AgentConnection.create!(tool: "get_resume", created_at: Time.current - i.minutes) }

    visit telemetry_path

    expect(page).to have_css('[data-telemetry-feed-target="list"]:not(.hidden)')

    page.execute_script(<<~JS)
      document.querySelector('[data-telemetry-feed-target="list"]').scrollTop = 200
    JS

    AgentConnection.create!(tool: "schedule_meeting", created_at: Time.current)

    # Trigger the controller's own (public) fetch/render cycle directly instead of waiting on its
    # real 5s `setInterval` — same production code path, without racing wall-clock timing.
    page.evaluate_async_script(<<~JS)
      const done = arguments[0]
      const element = document.querySelector('[data-controller="telemetry-feed"]')
      const controller = window.Stimulus.getControllerForElementAndIdentifier(element, "telemetry-feed")
      controller.fetchConnections().then(done)
    JS

    expect(page).to have_css('[data-telemetry-feed-target="list"] li', text: "schedule_meeting")

    scroll_top = page.evaluate_script('document.querySelector(\'[data-telemetry-feed-target="list"]\').scrollTop')
    expect(scroll_top).to eq(200)
  end

  it "leaves a gap between the scrollable list and its dates so the scrollbar doesn't cover them" do
    20.times { |i| AgentConnection.create!(tool: "get_resume", created_at: Time.current - i.minutes) }

    visit telemetry_path

    expect(page).to have_css('[data-telemetry-feed-target="list"].pr-3')
  end
end
