import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL_MS = 5000

export default class extends Controller {
  static targets = ["loading", "error", "empty", "list"]
  static values = { url: String }

  connect() {
    this.fetchConnections()
    this.intervalId = setInterval(() => this.fetchConnections(), POLL_INTERVAL_MS)
  }

  disconnect() {
    clearInterval(this.intervalId)
  }

  async fetchConnections() {
    try {
      const response = await fetch(this.urlValue)

      if (!response.ok) throw new Error("Failed to fetch telemetry")

      const connections = await response.json()

      this.#render(connections)
    } catch {
      this.#showOnly(this.errorTarget)
    }
  }

  #render(connections) {
    if (connections.length === 0) {
      this.#showOnly(this.emptyTarget)
      return
    }

    this.listTarget.innerHTML = connections
      .map(
        connection => `
          <li class="border-ctp-surface1/40 flex flex-wrap items-baseline gap-x-3 gap-y-1 border-b border-dashed py-2 font-mono text-xs last:border-b-0">
            <span class="text-ctp-green">➜</span>
            <span class="text-ctp-text break-words">${this.#escape(connection.tool)}</span>
            <span class="text-ctp-overlay0 ml-auto whitespace-nowrap max-[424px]:ml-0 max-[424px]:w-full">${new Date(connection.timestamp).toLocaleString()}</span>
          </li>
        `
      )
      .join("")

    this.#showOnly(this.listTarget)
    this.listTarget.classList.remove("hidden")
    this.listTarget.classList.add("flex")
  }

  #showOnly(target) {
    ;[ this.loadingTarget, this.errorTarget, this.emptyTarget, this.listTarget ].forEach(element => {
      element.classList.toggle("hidden", element !== target)
    })
  }

  #escape(value) {
    return String(value).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char])
  }
}
