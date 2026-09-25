require "rails_helper"

RSpec.describe DetectLocaleUseCase do
  subject(:use_case) { described_class.new }

  describe "when Cloudflare reports a country" do
    it "serves Portuguese to visitors in Brazil" do
      expect(use_case.execute(country_code: "BR")).to eq(:"pt-BR")
    end

    it "serves English to visitors anywhere else" do
      expect(use_case.execute(country_code: "US")).to eq(:en)
    end

    # A garbled code is still a country that isn't Brazil, so it vetoes like "ZZ" would.
    it "survives bytes that aren't valid UTF-8" do
      expect(use_case.execute(country_code: "B\xFFR", accept_language: "pt-BR")).to eq(:en)
    end

    # Deliberate: Brazil on an English laptop still gets Portuguese, and vice versa.
    it "ignores Accept-Language once a country is known" do
      expect(use_case.execute(country_code: "US", accept_language: "pt-BR,pt;q=0.9")).to eq(:en)
      expect(use_case.execute(country_code: "BR", accept_language: "en-US,en;q=0.9")).to eq(:"pt-BR")
    end

    it "normalizes the header's casing and whitespace" do
      expect(use_case.execute(country_code: " br ")).to eq(:"pt-BR")
    end

    # Deliberate — mapping PT/AO/MZ would serve Lisbon the wrong Portuguese.
    it "does not treat the other Lusophone countries as Portuguese-speaking" do
      %w[PT AO MZ CV].each do |country_code|
        result = use_case.execute(country_code: country_code, accept_language: "pt-PT,pt;q=0.9")

        expect(result).to eq(:en), "expected #{country_code} to fall back to English"
      end
    end
  end

  describe "when the country is missing or unusable" do
    # XX/T1 mean "couldn't place this client", not "not Brazil".
    [ nil, "", "XX", "T1" ].each do |country_code|
      it "falls back to Accept-Language for #{country_code.inspect}" do
        result = use_case.execute(country_code: country_code, accept_language: "pt-BR,pt;q=0.9")

        expect(result).to eq(:"pt-BR")
      end
    end

    it "matches on the primary subtag, so pt-PT gets the only Portuguese there is" do
      expect(use_case.execute(accept_language: "pt-PT")).to eq(:"pt-BR")
    end

    # Header values are case-insensitive, and the tag table is keyed in lowercase.
    it "ignores the header's casing and padding" do
      expect(use_case.execute(accept_language: "PT-BR,PT;q=0.9")).to eq(:"pt-BR")
      expect(use_case.execute(accept_language: "  de , PT ")).to eq(:"pt-BR")
    end

    it "skips languages the site doesn't have" do
      expect(use_case.execute(accept_language: "de,fr;q=0.9,pt;q=0.1")).to eq(:"pt-BR")
      expect(use_case.execute(accept_language: "de,fr;q=0.9")).to eq(:en)
    end

    # Written order is the whole rule — q-values are ignored, since browsers already list their
    # languages most-preferred first and this path only runs when Cloudflare sent no country.
    it "takes the first language the site has, in the header's own order" do
      expect(use_case.execute(accept_language: "en,pt")).to eq(:en)
      expect(use_case.execute(accept_language: "pt,en")).to eq(:"pt-BR")
      expect(use_case.execute(accept_language: "de,fr,es,pt,en")).to eq(:"pt-BR")
      expect(use_case.execute(accept_language: "en;q=0.3,pt;q=0.9")).to eq(:en)
    end

    it "ignores the * wildcard, which expresses no preference between en and pt-BR" do
      expect(use_case.execute(accept_language: "*")).to eq(:en)
    end

    it "returns the default locale on a malformed header instead of raising" do
      expect(use_case.execute(accept_language: ";;;q=")).to eq(:en)
      expect(use_case.execute(accept_language: "pt;q=notanumber")).to eq(:"pt-BR")
      expect(use_case.execute(accept_language: ",,,")).to eq(:en)
      expect(use_case.execute(accept_language: "pt;;;q=0.5;;")).to eq(:"pt-BR")
    end

    # Header values are raw bytes. Without the scrub, downcase and the regex both raise
    # ArgumentError here and the bare "/" 500s.
    it "survives bytes that aren't valid UTF-8" do
      expect(use_case.execute(accept_language: "\xFF\xFE")).to eq(:en)
      expect(use_case.execute(accept_language: "pt\xFF,en")).to eq(:"pt-BR")
      expect(use_case.execute(accept_language: "\xC3\x28,pt")).to eq(:"pt-BR")
    end

    it "handles a NUL byte and an absurdly long header" do
      expect(use_case.execute(accept_language: "pt\u0000,en")).to eq(:"pt-BR")
      expect(use_case.execute(accept_language: ([ "de" ] * 5_000).join(",") + ",pt")).to eq(:"pt-BR")
    end
  end

  it "defaults to English when there is nothing to go on" do
    expect(use_case.execute).to eq(:en)
  end

  # Nothing checks the return against the route constraint at runtime, and the constraint is its
  # own hardcoded regex — a locale outside it would 302 the bare "/" straight into a 404, so every
  # path that can produce one is exercised here rather than just the BR one.
  it "only ever returns a locale the /:locale route constraint accepts" do
    [
      { country_code: "BR" },
      { country_code: "US" },
      { country_code: "XX", accept_language: "pt-BR" },
      { accept_language: "de" },
      {}
    ].each do |signals|
      locale = use_case.execute(**signals)

      expect(Rails.application.routes.recognize_path("/#{locale}"))
        .to include(controller: "pages", action: "home"), "#{signals.inspect} produced #{locale.inspect}"
    end
  end
end
