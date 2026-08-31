import { Controller } from "@hotwired/stimulus"

// Catppuccin Frappé accents — kept in sync with app/assets/tailwind/application.css
const CATPPUCCIN_COLORS = [
  "#8caaee", // blue
  "#ca9ee6", // mauve
  "#a6d189", // green
  "#e5c890", // yellow
  "#81c8be", // teal
  "#babbf1", // lavender
  "#ef9f76", // peach
  "#f4b8e4", // pink
  "#e78284", // red
]
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
    const color = CATPPUCCIN_COLORS[this.colorIndex % CATPPUCCIN_COLORS.length]

    this.colorIndex += 1

    pixel.className = "cursor-trail-pixel"
    pixel.style.left = `${x}px`
    pixel.style.top = `${y}px`
    pixel.style.background = color

    document.body.appendChild(pixel)

    setTimeout(() => pixel.remove(), PIXEL_LIFETIME_MS)
  }
}
