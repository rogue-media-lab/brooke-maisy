import { Controller } from "@hotwired/stimulus"

// Search-as-you-type product picker for the quote builder.
// Fires a debounced fetch to /admin/products/search?q= on each keystroke.
// On focus with empty input, loads first 10 products (browse mode).
// Optional manufacturer filter narrows results to a single vendor.
// Renders matching products in a dropdown; clicking one fires a "selected" event
// that option_configurator_controller and swatch_picker_controller listen for.
export default class extends Controller {
  static targets = ["input", "results", "hidden", "manufacturer"]
  static values = { url: { type: String, default: "/admin/products/search" } }

  connect() {
    this._timeout = null
  }

  search() {
    clearTimeout(this._timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      // If manufacturer is selected, still browse — otherwise hide
      if (this.hasManufacturerTarget && this.manufacturerTarget.value) {
        this._fetchProducts("")
      } else {
        this.resultsTarget.innerHTML = ""
        this.resultsTarget.classList.add("hidden")
      }
      return
    }

    this._fetchProducts(query)
  }

  focus() {
    // Browse mode: if input is empty, load first 10 products on focus
    const query = this.inputTarget.value.trim()
    if (query.length === 0) {
      this._fetchProducts("")
    }
  }

  _fetchProducts(query) {
    let url = `${this.urlValue}?q=${encodeURIComponent(query)}`
    if (this.hasManufacturerTarget && this.manufacturerTarget.value) {
      url += `&manufacturer_id=${encodeURIComponent(this.manufacturerTarget.value)}`
    }

    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => {
      fetch(url)
        .then(r => r.json())
        .then(products => this._render(products))
        .catch(() => {
          this.resultsTarget.innerHTML = `<div class="p-2 text-sm text-gray-400">Search unavailable</div>`
          this.resultsTarget.classList.remove("hidden")
        })
    }, 200)
  }

  _render(products) {
    if (products.length === 0) {
      this.resultsTarget.innerHTML = `<div class="p-2 text-sm text-gray-400 italic">No products found</div>`
      this.resultsTarget.classList.remove("hidden")
      return
    }

    this.resultsTarget.innerHTML = products.map(p => {
      const specs = JSON.stringify(p.specs || {}).replace(/"/g, "&quot;")
      const pricing = JSON.stringify(p.pricing || {}).replace(/"/g, "&quot;")
      return `
        <button type="button"
                data-action="click->product-search#select"
                data-product-id="${p.id}"
                data-product-specs="${specs}"
                data-product-pricing="${pricing}"
                data-product-markup="${p.markup || 0.40}"
                class="w-full text-left px-3 py-2 hover:bg-theme-50 text-sm border-b border-gray-50 last:border-0 transition-colors">
          <span class="font-medium text-theme-500">${this._esc(p.name)}</span>
          <span class="text-gray-400 ml-2">${this._esc(p.manufacturer || "")}</span>
        </button>
      `
    }).join("")

    this.resultsTarget.classList.remove("hidden")
  }

  select(event) {
    const btn = event.currentTarget
    this.hiddenTarget.value = btn.dataset.productId
    this.inputTarget.value = btn.textContent.replace(/\s+/g, " ").trim()
    this.resultsTarget.classList.add("hidden")

    this.dispatch("selected", {
      detail: {
        id: btn.dataset.productId,
        specs: JSON.parse(btn.dataset.productSpecs || "{}"),
        pricing: JSON.parse(btn.dataset.productPricing || "{}"),
        markup: parseFloat(btn.dataset.productMarkup || "0.40")
      }
    })
  }

  blur() {
    // Delay so click registers before the dropdown disappears
    setTimeout(() => this.resultsTarget.classList.add("hidden"), 150)
  }

  _esc(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
