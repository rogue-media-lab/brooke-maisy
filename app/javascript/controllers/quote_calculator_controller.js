import { Controller } from "@hotwired/stimulus"

// Live client price preview as Amanda configures a line item.
// Interpolates base cost from product pricing reference points,
// applies mount type dimension adjustments, adds option upcharges,
// and applies markup. Amanda sees only the client price — never cost.
//
// The Ruby PricingCalculator service mirrors this logic server-side
// and runs on save as the source of truth.
export default class extends Controller {
  static targets = [
    "unitCost", "unitPrice", "quantity", "width", "height",
    "overrideCost", "priceDisplay", "upchargeTotal"
  ]
  static values = { markup: { type: Number, default: 0.40 } }

  connect() {
    this._pricingData = null
    this._specs = null
    this._selectedOptions = {}
    this.calculate()
  }

  // Called when a product is selected (listens for product-search:selected)
  loadPricing(event) {
    this._pricingData = event.detail.pricing || null
    this._specs = event.detail.specs || null
    if (event.detail.markup) {
      this.markupValue = event.detail.markup
    }
    this.calculate()
  }

  // Called when option configurator updates (listens for option-configurator:updated)
  // Also called on width/height/quantity/override changes
  calculate() {
    const width = parseFloat(this.widthTarget?.value) || 0
    const height = parseFloat(this.heightTarget?.value) || 0
    const quantity = parseInt(this.quantityTarget?.value) || 1
    const override = parseFloat(this.overrideCostTarget?.value) || null

    // Update selected options from the option configurator selects
    this._updateSelectedOptions()

    if (!this._pricingData && !override) {
      this._renderNoProduct()
      return
    }

    if (width === 0 || height === 0) {
      this._renderNeedDimensions()
      return
    }

    // Apply mount type dimension adjustments
    const { adjWidth, adjHeight, mountNote } = this._applyMountAdjustments(width, height)

    // Compute base cost (interpolated or override)
    const baseCost = override || this._interpolate(adjWidth, adjHeight)

    // Sum upcharges from option configurator selects
    const upcharges = this._sumUpcharges()

    const unitCost = baseCost + upcharges
    const unitPrice = unitCost * (1 + this.markupValue)
    const lineTotal = unitPrice * quantity

    // Store in hidden fields for form submission
    if (this.hasUnitCostTarget) this.unitCostTarget.value = unitCost.toFixed(2)
    if (this.hasUnitPriceTarget) this.unitPriceTarget.value = unitPrice.toFixed(2)

    // Render client-facing price display
    this._renderPrice(lineTotal, unitPrice, quantity, override, mountNote, upcharges)
  }

  // --- Rendering ---

  _renderNoProduct() {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTarget.innerHTML = `<p class="text-sm text-gray-400">Select a product to see pricing.</p>`
    }
  }

  _renderNeedDimensions() {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTarget.innerHTML = `<p class="text-sm text-gray-400">Enter dimensions to see price.</p>`
    }
  }

  _renderPrice(total, unitPrice, qty, override, mountNote, upcharges) {
    if (!this.hasPriceDisplayTarget) return

    const badge = override
      ? `<span class="inline-block mt-1 text-xs bg-amber-100 text-amber-700 px-2 py-0.5 rounded">Manual price</span>`
      : ""
    const note = mountNote
      ? `<p class="text-xs text-gray-400 mt-1">${mountNote}</p>`
      : ""
    const upchargeInfo = upcharges > 0
      ? `<p class="text-xs text-gray-400">Includes $${upcharges.toFixed(2)} in options</p>`
      : ""

    this.priceDisplayTarget.innerHTML = `
      <div class="text-2xl font-bold text-theme-500">$${total.toFixed(2)}</div>
      <p class="text-sm text-gray-400">$${unitPrice.toFixed(2)} each${qty > 1 ? ` × ${qty}` : ""}</p>
      ${upchargeInfo}
      ${note}
      ${badge}
    `
  }

  // --- Mount Type Adjustments ---

  _applyMountAdjustments(width, height) {
    const mountType = this._selectedOptions["mount_type"]
    if (!mountType || !this._specs) {
      return { adjWidth: width, adjHeight: height, mountNote: null }
    }

    const mountOptions = this._specs.mount_types || []
    const mount = mountOptions.find(m =>
      (typeof m === "object" && m.name === mountType) || m === mountType
    )

    if (!mount || typeof mount === "string") {
      return { adjWidth: width, adjHeight: height, mountNote: null }
    }

    const wAdj = mount.width_adjustment || 0
    const hAdj = mount.height_adjustment || 0
    const adjWidth = width + wAdj
    const adjHeight = height + hAdj

    const mountNote = (wAdj > 0 || hAdj > 0)
      ? `${mountType === "outside" ? "Outside mount" : mountType}: +${wAdj}" width, +${hAdj}" height`
      : null

    return { adjWidth, adjHeight, mountNote }
  }

  // --- Interpolation ---

  _interpolate(width, height) {
    const points = (this._pricingData?.price_points || []).slice().sort((a, b) => a.width - b.width)
    if (points.length === 0) return 0
    if (points.length === 1) {
      return this._applyHeightAdj(points[0].cost, points[0].height, height)
    }

    // Find bracketing points
    let r1, r2
    if (width <= points[0].width) {
      r1 = points[0]; r2 = points[1]
    } else if (width >= points[points.length - 1].width) {
      r1 = points[points.length - 2]; r2 = points[points.length - 1]
    } else {
      for (let i = 0; i < points.length - 1; i++) {
        if (width >= points[i].width && width <= points[i + 1].width) {
          r1 = points[i]; r2 = points[i + 1]
          break
        }
      }
    }

    if (!r1 || !r2) return points[0].cost

    // Exact width match
    if (r1.width === r2.width) {
      return this._applyHeightAdj(r1.cost, r1.height, height)
    }

    const widthRange = r2.width - r1.width
    const frac = (width - r1.width) / widthRange
    const interpCost = r1.cost + frac * (r2.cost - r1.cost)
    const interpHeight = r1.height + frac * (r2.height - r1.height)

    return this._applyHeightAdj(interpCost, interpHeight, height)
  }

  _applyHeightAdj(cost, refHeight, actualHeight) {
    if (!refHeight || refHeight <= 0) return cost
    const heightFactor = this._pricingData?.height_factor ?? 0.5
    const adjustment = 1 + heightFactor * (actualHeight - refHeight) / refHeight
    return cost * adjustment
  }

  // --- Upcharges ---

  _sumUpcharges() {
    let total = 0
    document.querySelectorAll("[data-option-configurator-target='field']").forEach(sel => {
      const opt = sel.selectedOptions[0]
      if (opt && opt.dataset.upcharge) {
        total += parseFloat(opt.dataset.upcharge) || 0
      }
    })
    return total
  }

  // --- Selected Options Tracking ---

  _updateSelectedOptions() {
    // Read all option configurator selects and build a selected_options hash
    document.querySelectorAll("[data-option-configurator-target='field']").forEach(sel => {
      const name = sel.getAttribute("name") || ""
      // Extract key from name like "quote_line_item[selected_options][lift_style]"
      const match = name.match(/\[selected_options\]\[(\w+)\]/)
      if (match && sel.selectedOptions[0]) {
        this._selectedOptions[match[1]] = sel.selectedOptions[0].value
      }
    })
  }
}
