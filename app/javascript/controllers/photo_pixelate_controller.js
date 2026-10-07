import { Controller } from "@hotwired/stimulus"

// Read from the active theme's --color-ctp-* variables in app/assets/tailwind/application.css
const PALETTE_COLORS = [
  "base", "mantle", "crust", "surface0", "surface1", "overlay0", "subtext0", "subtext1", "text",
  "blue", "mauve", "green", "yellow", "teal", "lavender", "peach", "pink", "red"
]

// 48x56 keeps cells perfectly square at the canvas's 300x350 display size
// (6.25px each) while resolving noticeably more facial detail than a coarser grid.
const GRID_COLUMNS = 48
const GRID_ROWS = 56
const TILE_GAP = 1
const TILE_RADIUS = 1.25

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
    if (!this.sourceTarget.naturalWidth) return

    // Captured once: the canvas is resized to device pixels below, so re-renders can't re-read it.
    this.displayWidth ??= this.canvasTarget.width
    this.displayHeight ??= this.canvasTarget.height
    this.palette = this.readPalette()

    const { displayWidth, displayHeight } = this

    // The source image's natural aspect ratio doesn't match the display box, and the
    // <img> uses object-cover (CSS crops it to fill the box, centered) — so the sampler
    // must crop the same region, or the mosaic ends up as a stretched, uncropped view
    // that's out of sync with the real photo shown on hover.
    const { sx, sy, sWidth, sHeight } = this.coverCrop(
      this.sourceTarget.naturalWidth,
      this.sourceTarget.naturalHeight,
      displayWidth,
      displayHeight
    )

    const sampler = document.createElement("canvas")
    sampler.width = GRID_COLUMNS
    sampler.height = GRID_ROWS

    const samplerContext = sampler.getContext("2d")
    samplerContext.drawImage(this.sourceTarget, sx, sy, sWidth, sHeight, 0, 0, GRID_COLUMNS, GRID_ROWS)

    const { data: pixels } = samplerContext.getImageData(0, 0, GRID_COLUMNS, GRID_ROWS)

    // Render tiles at device-pixel resolution instead of relying on CSS upscaling,
    // so each mosaic tile stays crisp (rather than blurry/aliased) at any zoom level.
    const dpr = window.devicePixelRatio || 1
    this.canvasTarget.width = displayWidth * dpr
    this.canvasTarget.height = displayHeight * dpr

    const context = this.canvasTarget.getContext("2d")
    context.scale(dpr, dpr)

    const cellWidth = displayWidth / GRID_COLUMNS
    const cellHeight = displayHeight / GRID_ROWS

    for (let row = 0; row < GRID_ROWS; row++) {
      for (let column = 0; column < GRID_COLUMNS; column++) {
        const index = (row * GRID_COLUMNS + column) * 4
        const [r, g, b] = this.nearestPaletteColor(pixels[index], pixels[index + 1], pixels[index + 2])

        context.fillStyle = `rgb(${r}, ${g}, ${b})`
        context.beginPath()
        context.roundRect(
          column * cellWidth + TILE_GAP / 2,
          row * cellHeight + TILE_GAP / 2,
          cellWidth - TILE_GAP,
          cellHeight - TILE_GAP,
          TILE_RADIUS
        )
        context.fill()
      }
    }
  }

  // Mirrors CSS object-fit: cover with the default centered object-position: scale the
  // source to fill the target box, then crop the overflow evenly from both sides.
  coverCrop(sourceWidth, sourceHeight, targetWidth, targetHeight) {
    const sourceRatio = sourceWidth / sourceHeight
    const targetRatio = targetWidth / targetHeight

    if (sourceRatio > targetRatio) {
      const sHeight = sourceHeight
      const sWidth = sourceHeight * targetRatio
      return { sx: (sourceWidth - sWidth) / 2, sy: 0, sWidth, sHeight }
    }

    const sWidth = sourceWidth
    const sHeight = sourceWidth / targetRatio
    return { sx: 0, sy: (sourceHeight - sHeight) / 2, sWidth, sHeight }
  }

  readPalette() {
    const styles = getComputedStyle(document.documentElement)

    return PALETTE_COLORS.map((name) => {
      const hex = styles.getPropertyValue(`--color-ctp-${name}`).trim().slice(1)

      return [0, 2, 4].map((offset) => parseInt(hex.slice(offset, offset + 2), 16))
    })
  }

  nearestPaletteColor(r, g, b) {
    let closest = this.palette[0]
    let closestDistance = Infinity

    for (const color of this.palette) {
      const distance = (r - color[0]) ** 2 + (g - color[1]) ** 2 + (b - color[2]) ** 2

      if (distance < closestDistance) {
        closestDistance = distance
        closest = color
      }
    }

    return closest
  }
}
