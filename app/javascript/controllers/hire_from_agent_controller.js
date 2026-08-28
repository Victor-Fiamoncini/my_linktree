import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { content: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.contentValue)

      this.buttonTarget.textContent = "Copied!"
      this.buttonTarget.classList.remove("text-[#89b4fa]", "hover:text-[#cdd6f4]")
      this.buttonTarget.classList.add("text-[#a6e3a1]")

      setTimeout(() => {
        this.buttonTarget.textContent = "Copy"
        this.buttonTarget.classList.add("text-[#89b4fa]", "hover:text-[#cdd6f4]")
        this.buttonTarget.classList.remove("text-[#a6e3a1]")
      }, 2000)
    } catch {
      // The browser can deny clipboard access; the snippet is still selectable/readable.
    }
  }
}
