import { Controller } from "@hotwired/stimulus"

// Model output is untrusted, so it only ever reaches the DOM through textContent.
export default class extends Controller {
  static targets = ["input", "fieldError", "submit", "banner", "result", "summary"]
  static values = { submitting: String, submitLabel: String, genericError: String, locale: String }

  async submit(event) {
    event.preventDefault()

    this.#reset()
    this.#setLoading(true)

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        },
        body: JSON.stringify({ job_description: this.inputTarget.value, locale: this.localeValue }),
      })

      const body = await response.json()

      if (response.ok) {
        this.#renderResult(body)
      } else {
        if (body.errors?.job_description) this.#showFieldError(body.errors.job_description)
        this.#showBanner(response.status === 500 ? this.genericErrorValue : body.message)
      }
    } catch {
      this.#showBanner(this.genericErrorValue)
    } finally {
      this.#setLoading(false)
    }
  }

  #renderResult({ summary }) {
    this.summaryTarget.textContent = summary
    this.resultTarget.classList.remove("hidden")
  }

  #reset() {
    this.fieldErrorTarget.classList.add("hidden")
    this.bannerTarget.classList.add("hidden")
    this.resultTarget.classList.add("hidden")
    this.summaryTarget.replaceChildren()
  }

  #showFieldError(message) {
    this.fieldErrorTarget.textContent = message
    this.fieldErrorTarget.classList.remove("hidden")
  }

  #showBanner(message) {
    this.bannerTarget.textContent = message
    this.bannerTarget.classList.remove("hidden")
  }

  #setLoading(isLoading) {
    this.submitTarget.disabled = isLoading
    this.submitTarget.value = isLoading ? this.submittingValue : this.submitLabelValue
  }
}
