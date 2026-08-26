import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const company = event.currentTarget.dataset.company

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.company === company
      const stateClass = isActive ? tab.dataset.activeClass : tab.dataset.inactiveClass

      tab.className = `${tab.dataset.baseClass} ${stateClass}`
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.company !== company)
    })
  }
}
