require "rails_helper"

RSpec.describe RateLimiter do
  let(:limiter) { described_class.new(key_prefix: "test", max_requests: 2, window: 10.seconds) }

  it "allows requests up to the limit and then rejects" do
    expect(limiter.allowed?("1.2.3.4")).to be true
    expect(limiter.allowed?("1.2.3.4")).to be true
    expect(limiter.allowed?("1.2.3.4")).to be false
  end

  it "tracks identifiers independently" do
    expect(limiter.allowed?("1.1.1.1")).to be true
    expect(limiter.allowed?("1.1.1.1")).to be true
    expect(limiter.allowed?("2.2.2.2")).to be true
  end

  it "always allows blank identifiers" do
    5.times { expect(limiter.allowed?(nil)).to be true }
  end

  it "resets after the window expires" do
    travel_to(Time.current) do
      limiter.allowed?("3.3.3.3")
      limiter.allowed?("3.3.3.3")
      expect(limiter.allowed?("3.3.3.3")).to be false
    end

    travel_to(11.seconds.from_now) do
      expect(limiter.allowed?("3.3.3.3")).to be true
    end
  end
end
