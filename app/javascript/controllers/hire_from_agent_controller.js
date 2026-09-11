import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { copyLabel: String, copiedLabel: String }

  async copy(event) {
    const button = event.currentTarget
    const { content } = event.params

    try {
      await navigator.clipboard.writeText(content)

      button.textContent = this.copiedLabelValue
      button.classList.remove("text-[#89b4fa]", "hover:text-[#cdd6f4]")
      button.classList.add("text-[#a6e3a1]")

      setTimeout(() => {
        button.textContent = this.copyLabelValue
        button.classList.add("text-[#89b4fa]", "hover:text-[#cdd6f4]")
        button.classList.remove("text-[#a6e3a1]")
      }, 2000)
    } catch {
      // The browser can deny clipboard access; the snippet is still selectable/readable.
    }
  }
}
