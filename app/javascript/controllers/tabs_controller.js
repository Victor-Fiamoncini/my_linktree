import { Controller } from "@hotwired/stimulus"

// A WAI-ARIA tablist: tabs and panels pair up by data-tabs-key. Styling hangs off aria-selected,
// so this only flips state. Arrow keys move between tabs, Home/End jump to the ends.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    this.activate(event.currentTarget)
  }

  navigate(event) {
    const moves = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }
    const tabs = this.tabTargets
    const current = tabs.indexOf(event.currentTarget)
    let next

    if (event.key in moves) next = (current + moves[event.key] + tabs.length) % tabs.length
    else if (event.key === "Home") next = 0
    else if (event.key === "End") next = tabs.length - 1
    else return

    event.preventDefault()
    this.activate(tabs[next])
    tabs[next].focus()
  }

  activate(tab) {
    const key = tab.dataset.tabsKey

    this.tabTargets.forEach((element) => {
      const isActive = element.dataset.tabsKey === key

      element.setAttribute("aria-selected", String(isActive))
      element.tabIndex = isActive ? 0 : -1
    })

    this.panelTargets.forEach((panel) => panel.classList.toggle("hidden", panel.dataset.tabsKey !== key))
  }
}
