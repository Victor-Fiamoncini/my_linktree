import { Controller } from "@hotwired/stimulus"

// Catppuccin Frappé palette — kept in sync with app/assets/tailwind/application.css
const CATPPUCCIN_PALETTE = [
  [48, 52, 70],    // base
  [41, 44, 60],    // mantle
  [35, 38, 52],    // crust
  [65, 69, 89],    // surface0
  [81, 87, 109],   // surface1
  [115, 121, 148], // overlay0
  [165, 173, 206], // subtext0
  [181, 191, 226], // subtext1
  [198, 208, 245], // text
  [140, 170, 238], // blue
  [202, 158, 230], // mauve
  [166, 209, 137], // green
  [229, 200, 144], // yellow
  [129, 200, 190], // teal
  [186, 187, 241], // lavender
  [239, 159, 118], // peach
  [244, 184, 228], // pink
  [231, 130, 132]  // red
]

const GRID_COLUMNS = 24
const GRID_ROWS = 28

export default class extends Controller {
  static targets = ["source", "canvas"]

  connect() {
    if (this.sourceTarget.complete) {
      this.render()
    } else {
      this.sourceTarget.addEventListener("load", () => this.render(), { once: true })
    }
  }

  render() {
    const sampler = document.createElement("canvas")
    sampler.width = GRID_COLUMNS
    sampler.height = GRID_ROWS

    const samplerContext = sampler.getContext("2d")
    samplerContext.drawImage(this.sourceTarget, 0, 0, GRID_COLUMNS, GRID_ROWS)

    const imageData = samplerContext.getImageData(0, 0, GRID_COLUMNS, GRID_ROWS)
    const pixels = imageData.data

    for (let i = 0; i < pixels.length; i += 4) {
      const [r, g, b] = this.nearestPaletteColor(pixels[i], pixels[i + 1], pixels[i + 2])
      pixels[i] = r
      pixels[i + 1] = g
      pixels[i + 2] = b
    }

    this.canvasTarget.width = GRID_COLUMNS
    this.canvasTarget.height = GRID_ROWS
    this.canvasTarget.getContext("2d").putImageData(imageData, 0, 0)
  }

  nearestPaletteColor(r, g, b) {
    let closest = CATPPUCCIN_PALETTE[0]
    let closestDistance = Infinity

    for (const color of CATPPUCCIN_PALETTE) {
      const distance = (r - color[0]) ** 2 + (g - color[1]) ** 2 + (b - color[2]) ** 2

      if (distance < closestDistance) {
        closestDistance = distance
        closest = color
      }
    }

    return closest
  }
}
