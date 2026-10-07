module ThemeHelper
  # Browser chrome color per theme: each flavor's blue.
  THEME_COLORS = { "frappe" => "#8caaee", "latte" => "#1e66f5" }.freeze
  DEFAULT_THEME = "frappe".freeze

  # Read from the cookie theme_controller.js writes, so the first paint is already themed.
  def current_theme
    cookies[:theme].presence_in(THEME_COLORS.keys) || DEFAULT_THEME
  end

  def theme_color
    THEME_COLORS.fetch(current_theme)
  end
end
