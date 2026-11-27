import { Controller } from "@hotwired/stimulus"

// The stack grid: picking an item shows where it was used. Text only, from the item's data attributes.
export default class extends Controller {
  static targets = ["item", "name", "usage"]

  pick(event) {
    const picked = event.currentTarget

    this.itemTargets.forEach((item) => item.setAttribute("aria-pressed", String(item === picked)))
    this.nameTarget.textContent = picked.dataset.name
    this.usageTarget.textContent = picked.dataset.usage
  }
}
