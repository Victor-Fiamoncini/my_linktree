import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { copyLabel: String, copiedLabel: String }

  async copy(event) {
    const button = event.currentTarget
    const { content } = event.params

    try {
      await navigator.clipboard.writeText(content)

      button.textContent = this.copiedLabelValue
      button.classList.replace("bg-ctp-peach", "bg-ctp-green")

      setTimeout(() => {
        button.textContent = this.copyLabelValue
        button.classList.replace("bg-ctp-green", "bg-ctp-peach")
      }, 2000)
    } catch {
      // The browser can deny clipboard access; the snippet is still selectable/readable.
    }
  }
}
