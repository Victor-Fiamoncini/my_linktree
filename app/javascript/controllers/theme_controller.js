import { Controller } from "@hotwired/stimulus"

// Kept in sync with ThemeHelper::THEME_COLORS
const THEME_COLORS = { frappe: "#8caaee", latte: "#1e66f5" }
const COOKIE_MAX_AGE = 60 * 60 * 24 * 365

export default class extends Controller {
  static targets = ["toggle", "switch"]
  static values = { titles: Object }

  toggle() {
    const theme = document.documentElement.dataset.theme === "latte" ? "frappe" : "latte"

    document.documentElement.dataset.theme = theme
    document.cookie = `theme=${theme}; path=/; max-age=${COOKIE_MAX_AGE}; samesite=lax`

    document
      .querySelectorAll('meta[name="theme-color"], meta[name="msapplication-navbutton-color"], meta[name="apple-mobile-web-app-status-bar-style"]')
      .forEach((meta) => meta.setAttribute("content", THEME_COLORS[theme]))

    this.toggleTargets.forEach((button) => button.setAttribute("aria-pressed", String(theme === "latte")))
    this.switchTargets.forEach((button) => button.setAttribute("aria-checked", String(theme === "latte")))
    for (const button of [...this.toggleTargets, ...this.switchTargets]) button.title = this.titlesValue[theme]

    this.dispatch("change", { detail: { theme } })
  }
}
