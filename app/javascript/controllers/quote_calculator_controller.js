import { Controller } from "@hotwired/stimulus"

// Live cost preview as Amanda configures a line item.
// Reads unit_cost × quantity, adds upcharges from option configurator selects.
export default class extends Controller {
  static targets = ["unitCost", "unitPrice", "quantity", "costPreview", "upchargeTotal"]
  static values = { markup: { type: Number, default: 0.40 } }

  connect() {
    this.calculate()
  }

  calculate() {
    const cost = parseFloat(this.unitCostTarget?.value) || 0
    const qty = parseInt(this.quantityTarget?.value) || 1
    const upcharges = this._sumUpcharges()

    const configuredCost = cost + upcharges
    const retail = configuredCost * (1 + this.markupValue)
    const total = retail * qty

    if (this.hasUpchargeTotalTarget) {
      this.upchargeTotalTarget.textContent = upcharges > 0 ? `+$${upcharges.toFixed(2)} upcharges` : ""
    }

    if (this.hasCostPreviewTarget) {
      this.costPreviewTarget.innerHTML = `
        <div class="text-xs space-y-1">
          <div class="flex justify-between"><span class="text-gray-400">Configured cost</span><span>$${configuredCost.toFixed(2)}</span></div>
          <div class="flex justify-between"><span class="text-gray-400">Suggested retail</span><span>$${retail.toFixed(2)}</span></div>
          <div class="flex justify-between font-semibold text-theme-500"><span>Line total (×${qty})</span><span>$${total.toFixed(2)}</span></div>
        </div>
      `
    }

    // Auto-fill unit_price if empty
    if (this.hasUnitPriceTarget && (!this.unitPriceTarget.value || this.unitPriceTarget.value === "0")) {
      this.unitPriceTarget.value = retail.toFixed(2)
    }
  }

  _sumUpcharges() {
    let total = 0
    const selects = document.querySelectorAll("[data-option-configurator-target='field']")
    selects.forEach(select => {
      const opt = select.selectedOptions[0]
      if (opt) {
        total += parseFloat(opt.dataset.upcharge) || 0
      }
    })
    return total
  }

  get markupValue() { return this.markupValue }
}