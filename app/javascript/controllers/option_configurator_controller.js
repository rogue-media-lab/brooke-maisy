import { Controller } from "@hotwired/stimulus"

// Dynamic option configurator driven by product.specs JSONB.
// Listens for product-search:selected event and renders the appropriate
// select fields (lift style, mount type, upgrades, warranty) with upcharges.
// Each field change dispatches an "updated" event for quote_calculator.
export default class extends Controller {
  static targets = ["container"]

  configure(event) {
    const { specs } = event.detail
    if (!specs || Object.keys(specs).length === 0) {
      this.containerTarget.innerHTML = ""
      return
    }

    let html = ""

    // Lift styles (with upcharges)
    if (Array.isArray(specs.lift_styles) && specs.lift_styles.length > 0) {
      html += this._selectField("lift_style", "Lift Style", specs.lift_styles)
    }

    // Mount types (flat array of strings — no upcharges)
    if (Array.isArray(specs.mount_types) && specs.mount_types.length > 0) {
      const mountOpts = specs.mount_types.map(m =>
        typeof m === "string" ? { name: m, upcharge: 0 } : m
      )
      html += this._selectField("mount_type", "Mount Type", mountOpts)
    }

    // Upgrades (already [{name, upcharge}, ...])
    if (Array.isArray(specs.upgrades) && specs.upgrades.length > 0) {
      html += this._selectField("upgrade", "Upgrade",
        [{ name: "None", upcharge: 0 }, ...specs.upgrades])
    }

    // Warranty options
    if (Array.isArray(specs.warranty_options) && specs.warranty_options.length > 0) {
      html += this._selectField("warranty", "Warranty", specs.warranty_options)
    }

    this.containerTarget.innerHTML = html
    this.dispatch("updated")
  }

  updateCost() {
    this.dispatch("updated")
  }

  _selectField(key, label, options) {
    const opts = options.map(o =>
      `<option value="${o.name}" data-upcharge="${o.upcharge || 0}">${this._esc(o.name)}${o.upcharge > 0 ? ` (+$${o.upcharge})` : ""}</option>`
    ).join("")

    return `
      <div class="mb-3">
        <label class="block text-xs font-semibold uppercase tracking-wider text-gray-500 mb-1">${label}</label>
        <select name="quote_line_item[selected_options][${key}]"
                class="w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500 text-sm"
                data-action="change->option-configurator#updateCost"
                data-upcharge-select="${key}">
          ${opts}
        </select>
      </div>
    `
  }
  _esc(str) {
    const div = document.createElement("div")
    div.textContent = `${str}`
    return div.innerHTML
  }
}