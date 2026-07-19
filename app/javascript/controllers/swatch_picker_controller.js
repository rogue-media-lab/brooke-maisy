import { Controller } from "@hotwired/stimulus"

// Color swatch grid for the quote builder.
// Listens for product-search:selected event, fetches that product's swatches
// from /admin/products/:id/swatches, and renders a clickable color grid.
// Amanda clicks a swatch; it highlights with a ring and updates the hidden input.
export default class extends Controller {
  static targets = ["swatch", "hidden", "grid"]
  static values = {
    swatchesUrl: { type: String, default: "/admin/products" },
    savedSwatchId: { type: String, default: "" }
  }

  loadSwatches(event) {
    const productId = event.detail.id
    if (!productId) return

    // Reset previous selection
    this.hiddenTarget.value = ""

    // Show loading state
    this.gridTarget.innerHTML = `<p class="text-sm text-gray-400 italic col-span-full">Loading colors...</p>`

    fetch(`${this.swatchesUrlValue}/${productId}/swatches`)
      .then(r => r.json())
      .then(swatches => this._renderSwatches(swatches))
      .catch(() => {
        this.gridTarget.innerHTML = `<p class="text-sm text-gray-400 italic col-span-full">Unable to load swatches.</p>`
      })
  }

  _renderSwatches(swatches) {
    if (swatches.length === 0) {
      this.gridTarget.innerHTML = `<p class="text-sm text-gray-400 italic col-span-full">No swatches available for this product.</p>`
      return
    }

    this.gridTarget.innerHTML = swatches.map(s => {
      const hex = s.hex || "#e5e5e5"
      const name = this._esc(s.name)
      return `
        <button type="button"
                data-swatch-picker-target="swatch"
                data-swatch-id="${s.id}"
                data-action="click->swatch-picker#select"
                class="w-full aspect-square rounded-lg border border-gray-200 hover:border-theme-400 transition-all cursor-pointer"
                style="background-color: ${hex}"
                title="${name}">
        </button>
      `
    }).join("")

    // Restore saved swatch selection on edit page
    if (this.savedSwatchIdValue) {
      const savedSwatch = this.swatchTargets.find(el => el.dataset.swatchId === this.savedSwatchIdValue)
      if (savedSwatch) {
        savedSwatch.classList.add("ring-2", "ring-theme-500", "ring-offset-1")
        this.hiddenTarget.value = this.savedSwatchIdValue
      }
    }
  }

  select(event) {
    const swatchEl = event.currentTarget

    // Remove highlight from all swatches
    this.swatchTargets.forEach(el => {
      el.classList.remove("ring-2", "ring-theme-500", "ring-offset-1")
    })

    // Highlight selected
    swatchEl.classList.add("ring-2", "ring-theme-500", "ring-offset-1")

    // Update hidden input
    this.hiddenTarget.value = swatchEl.dataset.swatchId
  }

  _esc(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
