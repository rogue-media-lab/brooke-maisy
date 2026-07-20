import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  fill(event) {
    const select = event.target
    const selectedOption = select.options[select.selectedIndex]
    if (!selectedOption || !selectedOption.value) return

    const width = selectedOption.dataset.width
    const height = selectedOption.dataset.height

    // Find the width and height input fields by their data attributes
    const form = select.closest("form")
    const widthInput = form.querySelector("[data-quote-calculator-target='width']")
    const heightInput = form.querySelector("[data-quote-calculator-target='height']")

    if (width && widthInput) {
      widthInput.value = width
      widthInput.dispatchEvent(new Event("input", { bubbles: true }))
    }

    if (height && heightInput) {
      heightInput.value = height
      heightInput.dispatchEvent(new Event("input", { bubbles: true }))
    }

    // Also try to set the location field to the room name
    const locationInput = form.querySelector("[name*='location']")
    if (locationInput && !locationInput.value) {
      const windowName = selectedOption.text
      if (windowName) locationInput.value = windowName
    }
  }
}
