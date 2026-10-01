require "rails_helper"

RSpec.describe ChunkTextUseCase do
  subject(:chunker) { described_class.new(max_chars: 60) }

  it "splits by heading and prefixes each chunk with its title and heading" do
    chunks = chunker.execute(text: "Intro\n\n# Setup\n\nRun it\n\n## Usage\n\nCall it", title: "repo")

    expect(chunks).to eq([ "repo\n\nIntro", "repo — Setup\n\nRun it", "repo — Usage\n\nCall it" ])
  end

  it "packs paragraphs up to the limit, overlapping neighbours by one paragraph" do
    text = "# Usage\n\nfirst paragraph here\n\nsecond paragraph here\n\nthird paragraph here"

    expect(chunker.execute(text: text, title: "repo")).to eq([
      "repo — Usage\n\nfirst paragraph here\n\nsecond paragraph here",
      "repo — Usage\n\nsecond paragraph here\n\nthird paragraph here"
    ])
  end

  it "hard-splits a paragraph longer than the limit, without overlap that wouldn't fit" do
    chunks = chunker.execute(text: "x" * 100, title: "t")

    expect(chunks).to eq([ "t\n\n#{"x" * 60}", "t\n\n#{"x" * 40}" ])
  end

  it "keeps fenced code intact, ignoring headings and blank lines inside it" do
    chunks = chunker.execute(text: "```sh\n# comment\n\necho hi\n```", title: "t")

    expect(chunks).to eq([ "t\n\n```sh\n# comment\n\necho hi\n```" ])
  end

  it "drops badges, HTML and comments, and skips sections left empty" do
    text = "[![CI](https://x/badge.svg)](https://x)\n<p align=\"center\">Hi</p>\n<!-- note -->\n\n# Empty\n\n# Real\n\nBody"

    expect(chunker.execute(text: text, title: "t")).to eq([ "t\n\nHi", "t — Real\n\nBody" ])
  end

  it "keeps angle brackets inside fenced and inline code while stripping real tags" do
    text = "Use `Vec<u8>` <b>here</b>, a < b > c.\n\n```rust\nfn f() -> Result<Vec<u8>, E> {}\n```\n\n<img\n  src=\"x\">"

    expect(chunker.execute(text: text, title: "t")).to eq([
      "t\n\nUse `Vec<u8>` here, a < b > c.",
      "t\n\n```rust\nfn f() -> Result<Vec<u8>, E> {}\n```"
    ])
  end
end
