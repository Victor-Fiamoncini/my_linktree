import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { copyLabel: String, copiedLabel: String }

  async copy(event) {
    const button = event.currentTarget
    const { content } = event.params

    try {
      await navigator.clipboard.writeText(content)

      button.textContent = this.copiedLabelValue
      button.classList.remove("text-term-blue", "hover:text-term-text")
      button.classList.add("text-term-green")

      setTimeout(() => {
        button.textContent = this.copyLabelValue
        button.classList.add("text-term-blue", "hover:text-term-text")
        button.classList.remove("text-term-green")
      }, 2000)
    } catch {
      // The browser can deny clipboard access; the snippet is still selectable/readable.
    }
  }
}
