# Splits Markdown into retrieval-sized chunks: by heading, then by paragraph, with one paragraph of
# overlap between neighbors. Each chunk is prefixed with its title and heading for context.
class ChunkTextUseCase
  HEADING = /\A\#{1,6}\s+(.+)\z/
  FENCE = /\A\s*(```|~~~)/
  BADGE_LINE = /\A\s*(\[?!\[[^\]]*\]\([^)]*\)\]?(\([^)]*\))?\s*)+\z/
  # Code (fenced or inline) is matched first and kept, so `Vec<u8>` isn't mistaken for an HTML tag.
  MARKUP = /(?<code>^[ \t]*(?<fence>```|~~~).*?^[ \t]*\k<fence>|`[^`\n]*`)|<!--.*?-->|<\/?[a-zA-Z][^<>]*>/m

  def initialize(max_chars: 2000)
    @max_chars = max_chars
  end

  def execute(text:, title:)
    sections(clean(text)).flat_map do |heading, paragraphs|
      label = [ title, heading ].compact.join(" — ")

      pack(paragraphs).map { |body| "#{label}\n\n#{body}" }
    end
  end

  private

  def clean(text)
    text.gsub(MARKUP) { $~[:code] || "" }.lines.map(&:rstrip).reject { |line| line.match?(BADGE_LINE) }
  end

  def sections(lines)
    sections = [ [ nil, [] ] ]
    paragraph = []
    in_fence = false

    flush = lambda do
      sections.last[1] << paragraph.join("\n").strip if paragraph.join.strip.present?

      paragraph = []
    end

    lines.each do |line|
      in_fence = !in_fence if line.match?(FENCE)

      if !in_fence && (heading = line[HEADING, 1])
        flush.call
        sections << [ heading.strip, [] ]
      elsif !in_fence && line.strip.empty?
        flush.call
      else
        paragraph << line
      end
    end

    flush.call

    sections.reject { |_, paragraphs| paragraphs.empty? }
  end

  def pack(paragraphs)
    pieces = paragraphs.flat_map { |paragraph| paragraph.scan(/.{1,#{@max_chars}}/m) }
    chunks = []
    current = []

    pieces.each do |piece|
      if current.any? && (current + [ piece ]).join("\n\n").length > @max_chars
        chunks << current
        overlap = current.last
        current = overlap.length + piece.length + 2 <= @max_chars ? [ overlap ] : []
      end

      current << piece
    end

    chunks << current

    chunks.map { |chunk| chunk.join("\n\n") }
  end
end
