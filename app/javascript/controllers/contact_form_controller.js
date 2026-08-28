import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fieldError", "submit", "banner"]

  async submit(event) {
    event.preventDefault()

    this.#clearErrors()
    this.#setLoading(true)

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.#csrfToken(),
        },
        body: JSON.stringify(this.#formData()),
      })

      const body = await response.json()

      if (response.ok) {
        this.element.reset()
        this.#showBanner(body.message, "success")
      } else if (body.errors) {
        this.#showFieldErrors(body.errors)
        this.#showBanner(body.message, "error")
      } else {
        this.#showBanner(body.message, "error")
      }
    } catch {
      this.#showBanner("Something went wrong. Please check your connection and try again.", "error")
    } finally {
      this.#setLoading(false)
    }
  }

  #formData() {
    return Object.fromEntries(this.inputTargets.map(input => [input.dataset.field, input.value]))
  }

  #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }

  #clearErrors() {
    this.fieldErrorTargets.forEach(element => {
      element.textContent = ""
      element.classList.add("hidden")
    })
    this.bannerTarget.classList.add("hidden")
    this.submitTarget.classList.remove("hidden")
  }

  #showFieldErrors(errors) {
    this.fieldErrorTargets.forEach(element => {
      const message = errors[element.dataset.field]
      if (!message) return

      element.textContent = message
      element.classList.remove("hidden")
    })
  }

  #showBanner(message, kind) {
    this.bannerTarget.textContent = message
    this.bannerTarget.classList.remove("hidden", "text-ctp-green", "text-ctp-red")
    this.bannerTarget.classList.add(kind === "success" ? "text-ctp-green" : "text-ctp-red")
    this.submitTarget.classList.add("hidden")
  }

  #setLoading(isLoading) {
    this.submitTarget.disabled = isLoading
    this.submitTarget.textContent = isLoading ? "Sending..." : "Reach Out"
  }
}
