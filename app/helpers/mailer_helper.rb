module MailerHelper
  # Catppuccin Frappé, the hexes from app/assets/tailwind/application.css. Mail clients need them inline.
  # line/ink/drop mirror the page's --color-line, --color-ink and --color-px-shadow; term_* its terminal panels.
  FRAPPE = {
    crust: "#232634", mantle: "#292c3c", base: "#303446", surface0: "#414559",
    overlay1: "#838ba7", subtext0: "#a5adce", subtext1: "#b5bfe2", text: "#c6d0f5",
    blue: "#8caaee", mauve: "#ca9ee6", green: "#a6d189", pink: "#f4b8e4", peach: "#ef9f76",
    line: "#838ba7", ink: "#232634", drop: "#232634", on_strong: "#232634",
    term_bg: "#1e1e2e", term_green: "#a6e3a1"
  }.freeze

  # Pixel only frames things, as on the page: Pixelify for headings, labels and buttons, Atkinson for
  # running text. Gmail ignores web fonts, so the pixel stack falls back to a monospace.
  FONT_SANS = %("Atkinson Hyperlegible Next", "Atkinson Hyperlegible", -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif).freeze
  FONT_PIXEL = %("Pixelify Sans", "JetBrains Mono", ui-monospace, Menlo, Consolas, monospace).freeze
  FONT_MONO = %("JetBrains Mono", ui-monospace, Menlo, Consolas, monospace).freeze
  # Pixelify's "fi" ligature draws a glyph that reads as "A" ("conArmed"), so it's always switched off.
  PIXEL_TYPE = "font-family:#{FONT_PIXEL};font-variant-ligatures:none;".freeze

  # The page's px-panel / px-raised frame, drawn with table cells instead of box-shadow (which Gmail
  # drops): a `unit`-thick outline with notched corners and, with `drop`, a one-step shadow.
  #
  #   . L L L .        L = line, C = content (fill), D = drop, . = transparent
  #   L C C C L D
  #   . L L L D D
  #   . D D D D .
  def mail_px_box(fill:, line:, drop: nil, unit: 4, full_width: false, cell_style: "", table_style: "", &block)
    dot = ->(color = nil) { px_cell(color, width: unit, height: unit) }
    hbar = ->(color) { px_cell(color, height: unit) }
    vbar = ->(color) { px_cell(color, width: unit) }

    rows = [
      [ dot.(nil), hbar.(line), dot.(nil), (dot.(nil) if drop) ],
      [ vbar.(line), tag.td(capture(&block), style: "background-color:#{fill};#{cell_style}"), vbar.(line), (vbar.(drop) if drop) ],
      [ dot.(nil), hbar.(line), dot.(drop), (dot.(drop) if drop) ]
    ]
    rows << [ dot.(nil), hbar.(drop), dot.(drop), dot.(nil) ] if drop

    tag.table(role: "presentation", width: ("100%" if full_width), cellpadding: 0, cellspacing: 0, border: 0, style: table_style) do
      safe_join(rows.map { |cells| tag.tr(safe_join(cells.compact)) })
    end
  end

  # The mono chip above each heading, like shared/_section_heading's prompt.
  def mail_prompt(text, color)
    chip_style = "margin:0;padding:4px 10px;font-family:#{FONT_MONO};font-size:13px;font-weight:700;line-height:1.4;color:#{FRAPPE[:on_strong]};"

    mail_px_box(fill: FRAPPE[color], line: FRAPPE[:ink], drop: FRAPPE[:ink], unit: 2, table_style: "margin:0 0 16px;") do
      tag.p(text, style: chip_style)
    end
  end

  def mail_heading(text)
    tag.h1(text, style: "margin:0 0 24px;#{PIXEL_TYPE}font-size:34px;font-weight:600;line-height:1.05;color:#{FRAPPE[:text]};")
  end

  # Wraps mail_field rows, so templates never open a table by hand.
  def mail_fields(&block)
    tag.table(role: "presentation", width: "100%", cellpadding: 0, cellspacing: 0, border: 0, &block)
  end

  # One label/value row; the value is escaped before simple_format so line breaks survive but markup doesn't.
  def mail_field(label, value)
    label_style = "padding:16px 0 4px;#{PIXEL_TYPE}font-size:14px;font-weight:500;color:#{FRAPPE[:subtext0]};"
    value_style = "padding:0 0 14px;border-bottom:2px solid #{FRAPPE[:surface0]};font-family:#{FONT_SANS};font-size:16px;line-height:1.6;color:#{FRAPPE[:text]};"

    safe_join([
      tag.tr { tag.td(label, style: label_style) },
      tag.tr { tag.td(simple_format(h(value), { style: "margin:0 0 10px;" }, wrapper_tag: "div"), style: value_style) }
    ])
  end

  # A framed link inside a table cell, the only button shape Outlook renders with padding and a background.
  def mail_button(label, url)
    link_style = "display:inline-block;padding:12px 22px;#{PIXEL_TYPE}font-size:16px;font-weight:600;color:#{FRAPPE[:on_strong]};text-decoration:none;"

    mail_px_box(fill: FRAPPE[:blue], line: FRAPPE[:ink], drop: FRAPPE[:ink], table_style: "margin:28px 0 6px;") do
      link_to(label, url, style: link_style)
    end
  end

  private

  # Fixed-size cells need font-size/line-height 0, or clients pad them out to a line of text.
  def px_cell(color, width: nil, height: nil)
    style = "font-size:0;line-height:0;"
    style += "width:#{width}px;" if width
    style += "height:#{height}px;" if height
    style += "background-color:#{color};" if color

    tag.td("", width: width, height: height, style: style)
  end
end
