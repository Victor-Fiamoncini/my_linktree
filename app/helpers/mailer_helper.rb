module MailerHelper
  # Catppuccin Frappé, the hexes from app/assets/tailwind/application.css. Mail clients need them inline.
  FRAPPE = {
    crust: "#232634", mantle: "#292c3c", base: "#303446", surface0: "#414559",
    overlay1: "#838ba7", subtext0: "#a5adce", text: "#c6d0f5",
    blue: "#8caaee", mauve: "#ca9ee6", green: "#a6d189", pink: "#f4b8e4",
    ink: "#c6d0f5", on_strong: "#232634"
  }.freeze

  # Hard offset shadows; Gmail drops box-shadow, leaving the thick ink border.
  BRUT_SHADOW_SM = "4px 4px 0 0 #{FRAPPE[:ink]}".freeze
  BRUT_SHADOW = "6px 6px 0 0 #{FRAPPE[:ink]}".freeze

  FONT_SANS = %("Space Grotesk", -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif).freeze
  FONT_MONO = %("JetBrains Mono", ui-monospace, Menlo, Consolas, monospace).freeze

  # The mono chip above each heading, like shared/_section_heading's prompt (unrotated: clients drop transform).
  def mail_prompt(text, color)
    style = "display:inline-block;margin:0 0 18px;padding:6px 12px;background-color:#{FRAPPE[color]};border:3px solid #{FRAPPE[:ink]};" \
      "box-shadow:#{BRUT_SHADOW_SM};font-family:#{FONT_MONO};font-size:13px;font-weight:800;line-height:1.4;color:#{FRAPPE[:on_strong]};"

    tag.p(text, style: style)
  end

  def mail_heading(text)
    tag.h1(text, style: "margin:0 0 24px;font-family:#{FONT_SANS};font-size:30px;font-weight:700;letter-spacing:-0.03em;line-height:1.1;color:#{FRAPPE[:text]};")
  end

  # Wraps mail_field rows, so templates never open a table by hand.
  def mail_fields(&block)
    tag.table(role: "presentation", width: "100%", cellpadding: 0, cellspacing: 0, border: 0, &block)
  end

  # One label/value row; the value is escaped before simple_format so line breaks survive but markup doesn't.
  def mail_field(label, value)
    label_style = "padding:16px 0 4px;font-family:#{FONT_MONO};font-size:12px;font-weight:800;letter-spacing:0.08em;text-transform:uppercase;color:#{FRAPPE[:subtext0]};"
    value_style = "padding:0 0 14px;border-bottom:3px solid #{FRAPPE[:surface0]};font-family:#{FONT_SANS};font-size:15px;line-height:1.6;color:#{FRAPPE[:text]};"

    safe_join([
      tag.tr { tag.td(label, style: label_style) },
      tag.tr { tag.td(simple_format(h(value), { style: "margin:0 0 10px;" }, wrapper_tag: "div"), style: value_style) }
    ])
  end

  # A table-wrapped link, the only button shape Outlook renders with padding and a background.
  def mail_button(label, url)
    link_style = "display:inline-block;padding:14px 26px;font-family:#{FONT_SANS};font-size:16px;font-weight:700;color:#{FRAPPE[:on_strong]};text-decoration:none;"
    cell_style = "background-color:#{FRAPPE[:blue]};border:3px solid #{FRAPPE[:ink]};box-shadow:#{BRUT_SHADOW};"

    tag.table(role: "presentation", cellpadding: 0, cellspacing: 0, border: 0, style: "margin:28px 0 6px;") do
      tag.tr { tag.td(link_to(label, url, style: link_style), style: cell_style) }
    end
  end
end
