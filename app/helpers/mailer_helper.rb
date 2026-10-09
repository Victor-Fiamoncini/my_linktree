module MailerHelper
  # Catppuccin Frappé, the hexes from app/assets/tailwind/application.css. Mail clients need them inline.
  FRAPPE = {
    crust: "#232634", mantle: "#292c3c", base: "#303446", surface0: "#414559",
    overlay1: "#838ba7", subtext0: "#a5adce", text: "#c6d0f5",
    blue: "#8caaee", mauve: "#ca9ee6", green: "#a6d189"
  }.freeze

  FONT_SANS = %("Space Grotesk", -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif).freeze
  FONT_MONO = %("JetBrains Mono", ui-monospace, Menlo, Consolas, monospace).freeze

  def mail_heading(text)
    tag.h1(text, style: "margin:0 0 20px;font-family:#{FONT_SANS};font-size:22px;font-weight:600;line-height:1.3;color:#{FRAPPE[:text]};")
  end

  # Wraps mail_field rows, so templates never open a table by hand.
  def mail_fields(&block)
    tag.table(role: "presentation", width: "100%", cellpadding: 0, cellspacing: 0, border: 0, &block)
  end

  # One label/value row; the value is escaped before simple_format so line breaks survive but markup doesn't.
  def mail_field(label, value)
    label_style = "padding:14px 0 4px;font-family:#{FONT_MONO};font-size:12px;letter-spacing:0.06em;text-transform:uppercase;color:#{FRAPPE[:subtext0]};"
    value_style = "padding:0 0 14px;border-bottom:1px solid #{FRAPPE[:surface0]};font-family:#{FONT_SANS};font-size:15px;line-height:1.6;color:#{FRAPPE[:text]};"

    safe_join([
      tag.tr { tag.td(label, style: label_style) },
      tag.tr { tag.td(simple_format(h(value), { style: "margin:0 0 10px;" }, wrapper_tag: "div"), style: value_style) }
    ])
  end

  # A table-wrapped link, the only button shape Outlook renders with padding and a background.
  def mail_button(label, url)
    link_style = "display:inline-block;padding:12px 22px;font-family:#{FONT_SANS};font-size:15px;font-weight:600;color:#{FRAPPE[:crust]};text-decoration:none;"

    tag.table(role: "presentation", cellpadding: 0, cellspacing: 0, border: 0, style: "margin:24px 0 4px;") do
      tag.tr { tag.td(link_to(label, url, style: link_style), style: "background-color:#{FRAPPE[:mauve]};") }
    end
  end
end
