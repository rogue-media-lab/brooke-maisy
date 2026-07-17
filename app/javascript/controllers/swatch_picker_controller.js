import { Controller } from "@hotwired/stimulus"

// Clickable color swatch grid for the quote builder.
// Amanda clicks a swatch; it highlights with a ring and updates the hidden input.
export default class extends Controller {
  static targets = ["swatch", "hidden"]

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
}