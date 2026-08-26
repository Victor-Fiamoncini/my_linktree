import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "email", "message", "submitButton", "successMessage", "errorMessage"]

  async submit(event) {
    event.preventDefault()

    this.#hideMessages()
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Sending..."

    try {
      const response = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: this.nameTarget.value,
          email: this.emailTarget.value,
          message: this.messageTarget.value,
        }),
      })

      if (response.ok) {
        this.element.reset()
        this.successMessageTarget.classList.remove("hidden")
      } else {
        this.errorMessageTarget.classList.remove("hidden")
      }
    } catch {
      this.errorMessageTarget.classList.remove("hidden")
    } finally {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = "Reach Out"
    }
  }

  #hideMessages() {
    this.successMessageTarget.classList.add("hidden")
    this.errorMessageTarget.classList.add("hidden")
  }
}
