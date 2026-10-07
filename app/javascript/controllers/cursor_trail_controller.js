import { Controller } from "@hotwired/stimulus"

// Resolved per pixel from the active theme's --color-ctp-* variables, so the trail follows the toggle
const TRAIL_COLORS = ["blue", "mauve", "green", "yellow", "teal", "lavender", "peach", "pink", "red"]
const SPAWN_INTERVAL_MS = 40
const PIXEL_LIFETIME_MS = 650

export default class extends Controller {
  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.colorIndex = 0
    this.lastSpawnAt = 0
    this.onPointerMove = this.onPointerMove.bind(this)

    document.addEventListener("pointermove", this.onPointerMove, { passive: true })
  }

  disconnect() {
    document.removeEventListener("pointermove", this.onPointerMove)
  }

  onPointerMove(event) {
    const now = performance.now()

    if (now - this.lastSpawnAt < SPAWN_INTERVAL_MS) return

    this.lastSpawnAt = now
    this.spawnPixel(event.clientX, event.clientY)
  }

  spawnPixel(x, y) {
    const pixel = document.createElement("span")
    const color = TRAIL_COLORS[this.colorIndex % TRAIL_COLORS.length]

    this.colorIndex += 1

    pixel.className = "cursor-trail-pixel"
    pixel.style.left = `${x}px`
    pixel.style.top = `${y}px`
    pixel.style.background = `var(--color-ctp-${color})`

    document.body.appendChild(pixel)

    setTimeout(() => pixel.remove(), PIXEL_LIFETIME_MS)
  }
}
