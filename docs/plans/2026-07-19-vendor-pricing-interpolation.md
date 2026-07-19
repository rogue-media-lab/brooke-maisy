# Vendor Pricing Interpolation System — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Auto-calculate product costs from reference price points so Amanda never sees or types cost in front of a client. The quote form shows only the client price, computed from dimensions + options + markup.

**Architecture:** Store reference price points at standard U.S. window sizes per product in the existing `pricing` JSONB column. A `PricingCalculator` service interpolates a base cost from those points, adds option upcharges (already in `specs` JSONB), and applies the markup (already in settings). The quote form hides cost fields entirely; client price updates live as Amanda configures the line item.

**Tech Stack:** Rails 8, Ruby service objects, Stimulus (existing quote-calculator controller), JSONB columns (already migrated), Tailwind views.

---

## Standard Window Size Reference Grid

Instead of arbitrary price points, we capture prices at standard U.S. window sizes. Most quotes hit a reference point exactly (zero interpolation error). Non-standard sizes interpolate between the two nearest standard sizes — tight gaps, small error.

### Standard Sizes (researched from Pella, MI Windows, HomeGuide)

**Double-Hung / Single-Hung (most common):**
- Widths: 24, 28, 32, 36, 40, 44, 48
- Heights: 36, 44, 48, 52, 54, 60, 72

**Sliding / Picture:**
- Widths: 36, 48, 60, 72
- Heights: 24, 36, 48, 60

### Key Reference Sizes (10-12 points per product)

These cover the full standard range with the most common sizes prioritized:

| # | Width | Height | Typical Location |
|---|-------|--------|-----------------|
| 1 | 24 | 36 | Kitchen above sink, bathroom |
| 2 | 28 | 44 | Bedroom |
| 3 | 28 | 52 | Bedroom |
| 4 | 32 | 48 | Common mid-size |
| 5 | 36 | 48 | Very common |
| 6 | 36 | 60 | Most common double-hung |
| 7 | 48 | 48 | Sliding / picture |
| 8 | 48 | 60 | Living room |
| 9 | 60 | 60 | Large |
| 10 | 72 | 48 | Wide / sliding |

### Why This Works

- Quotes at standard sizes = exact price, no interpolation needed
- Non-standard sizes interpolate between nearest 2 standard points (4-8" gap in width)
- The standard range (24"-72" wide, 36"-72" tall) covers virtually all residential windows
- Edge extrapolation rarely needed — only for custom/non-standard builds (Amanda uses override_cost for those)
- Research workflow is structured: "go to vendor site, configure each standard size, record the price"

### Accuracy With Standard Grid

With 10 reference points across the standard range:
- At reference point: exact (0% error)
- Between two adjacent points (e.g., 30x42 between 28x44 and 32x48): estimated $3-6 error
- Edge cases (outside standard range): Amanda uses override_cost

Compare to 4 arbitrary points: $12-20 error in the middle, $15-25 at edges.

---

## The Interpolation Model

### Why Not Linear?

Tested against real SelectBlinds data (Cordless Light Filtering Cellular Shades):

| Size | Area (sq in) | Actual Price | Linear Estimate | Error |
|------|-------------|-------------|-----------------|-------|
| 24x36 | 864 | $71.99 | $71.99 (ref) | — |
| 36x48 | 1728 | $146.99 | $132.98 | -$14.01 |
| 60x60 | 3600 | $243.99 | $256.13 | +$12.14 |
| 72x48 | 3456 | $254.99 | $254.99 (ref) | — |

Linear-by-area misses by $12-14 in the middle. Worse: 72x48 (3456 sq in) costs MORE than 60x60 (3600 sq in) despite less area. Width is the primary driver, not area.

### The Approach: Width-Based Piecewise Linear + Height Adjustment

1. Sort reference points by width.
2. Find the two points that bracket the requested width.
3. Linearly interpolate cost and height at that width fraction.
4. Apply height adjustment: `estimated = interpolated_cost × (1 + height_factor × (H_requested - H_interpolated) / H_interpolated)`
5. `height_factor` is configurable per product (default 0.5, meaning 50% of the height difference affects price).

### Cross-Validation Results (height_factor=0.5)

Leave-one-out testing with 4 reference points:

| Size | Estimated | Actual | Error | % |
|------|-----------|--------|-------|---|
| 24x36 | $91.46 | $71.99 | +$19.47 | 27% (edge) |
| 36x48 | $135.20 | $146.99 | -$11.79 | 8% |
| 60x60 | $246.36 | $243.99 | +$2.37 | 1% |
| 72x48 | $252.61 | $254.99 | -$2.38 | 1% |

**Middle of range: within $3.** Edge extrapolation: up to $20 error.

### With a 5th Reference Point (48x48 = $189.99)

| Size | Estimated | Actual | Error | % |
|------|-----------|--------|-------|---|
| 36x48 | $140.35 | $146.99 | -$6.64 | 4.5% |
| 60x60 | $250.30 | $243.99 | +$6.31 | 2.6% |
| 72x48 | $248.33 | $254.99 | -$6.66 | 2.6% |

Adding points in the middle tightens the middle to ~$6. Edge points remain the weak spot.

### Accuracy Expectations

| Reference Points | Middle Error | Edge Error |
|-----------------|-------------|------------|
| 2 (min/max) | $10-15 | $15-25 |
| 4 (current) | $2-12 | $15-20 |
| 5-6 (recommended) | $5-7 | $10-15 |
| 8+ (grid) | $3-5 | $5-10 |

**The margin absorbs the variance.** At 40% markup, a $12 cost error on a $147 item is 8% of cost — well within margin. The client price is locked at quote time. If actual cost comes in $12 lower, Amanda makes $12 more. If $12 higher, she makes $12 less. The ranch stays unsold.

### Manual Override

For unusual sizes (outside reference range, or Amanda has a verified vendor quote):
- Line item has an optional `override_cost` field (decimal)
- When present, the calculator uses `override_cost` instead of interpolation
- No override = interpolated cost (default path)
- Amanda sees a "Verified price" badge when override is active

### Mount Type Dimension Adjustments

Inside mount vs outside mount changes the actual blind size, which changes the cost:
- **Inside mount**: blind fits inside the frame. Dimensions = window dimensions as entered.
- **Outside mount**: blind covers the frame. Width increases by a coverage allowance (typically +4"), height may increase (headrail allowance, typically +2").

Since price is width-driven, outside mount costs more — not as a flat upcharge, but because the blind is physically larger. The system applies the adjustment automatically before pricing.

Stored in product specs JSONB alongside mount_types:
```json
"mount_types": [
  { "name": "inside", "upcharge": 0, "width_adjustment": 0, "height_adjustment": 0 },
  { "name": "outside", "upcharge": 0, "width_adjustment": 4, "height_adjustment": 2 }
]
```

The PricingCalculator:
1. Checks the selected mount type from selected_options
2. Looks up width_adjustment and height_adjustment for that mount type
3. Applies them to the entered dimensions BEFORE interpolation
4. Price reflects the actual blind size, not the window size

The quote form:
- Shows the actual window dimensions Amanda entered (e.g., 36x48)
- Client price is calculated on the adjusted blind size (e.g., 40x50 for outside mount)
- Amanda doesn't manually add coverage — the system handles it per the vendor's specs
- A small note appears: "Outside mount: +4\" width, +2\" height" so Amanda knows the adjustment was applied

Per-product configurable because vendors have different coverage requirements. The research workflow captures the vendor's recommended outside mount allowance.

---

## Data Model

### Product.pricing JSONB Structure

Already exists — the `pricing` column on `products` is a JSONB column. No migration needed.

```json
{
  "price_points": [
    { "width": 24, "height": 36, "cost": 71.99 },
    { "width": 36, "height": 48, "cost": 146.99 },
    { "width": 60, "height": 60, "cost": 243.99 },
    { "width": 72, "height": 48, "cost": 254.99 }
  ],
  "height_factor": 0.5,
  "last_verified": "2026-07-19",
  "verified_by": "Mason"
}
```

- `price_points`: array of {width, height, cost} reference points. Minimum 2 for interpolation.
- `height_factor`: float, default 0.5. Controls how much height affects price. 0 = width only, 1 = proportional to height, 0.5 = half the height ratio effect.
- `last_verified`: date string. When Amanda or Mason last checked prices against the vendor site.
- `verified_by`: who verified. Optional, for audit.

### QuoteLineItem Changes

One migration: add `override_cost` column (decimal, nullable).

```ruby
# db/migrate/XXXXXXXX_add_override_cost_to_quote_line_items.rb
class AddOverrideCostToQuoteLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :quote_line_items, :override_cost, :decimal, precision: 8, scale: 2
  end
end
```

Add `:override_cost` to `line_item_params` in `Admin::QuoteLineItemsController`.

---

## PricingCalculator Service

### File: `app/services/pricing_calculator.rb`

```ruby
class PricingCalculator
  # Input: product (Product), width (Float), height (Float), selected_options (Hash)
  # Output: Hash with base_cost, upcharges_total, unit_cost, unit_price, line_total, method

  def initialize(product, width, height, selected_options = {}, quantity = 1, override_cost = nil)
    @product = product
    @width = width.to_f
    @height = height.to_f
    @selected_options = selected_options || {}
    @quantity = quantity.to_i
    @override_cost = override_cost
  end

  def calculate
    # Apply mount type dimension adjustments BEFORE interpolation
    adjusted_width, adjusted_height = apply_mount_adjustments

    base_cost = compute_base_cost(adjusted_width, adjusted_height)
    upcharges = sum_upcharges
    unit_cost = base_cost + upcharges
    markup = fetch_markup
    unit_price = unit_cost * (1 + markup)
    line_total = unit_price * @quantity

    {
      base_cost: base_cost,
      upcharges_total: upcharges,
      unit_cost: unit_cost,
      unit_price: unit_price,
      line_total: line_total,
      adjusted_width: adjusted_width,
      adjusted_height: adjusted_height,
      method: @method # :interpolated, :override, :no_pricing, :manual
    }
  end

  private

  def apply_mount_adjustments
    mount_type = @selected_options["mount_type"]
    return [@width, @height] unless mount_type

    specs = @product.specs || {}
    mount_options = specs["mount_types"] || []
    # mount_types can be array of strings (old format) or array of hashes (new format)
    mount = mount_options.find do |m|
      m.is_a?(Hash) ? m["name"] == mount_type : m == mount_type
    end

    return [@width, @height] unless mount.is_a?(Hash)

    w_adj = mount["width_adjustment"].to_f
    h_adj = mount["height_adjustment"].to_f
    [@width + w_adj, @height + h_adj]
  end

  def compute_base_cost(width, height)
    return @override_cost.to_f if @override_cost.present?
    return 0.0 if pricing_data.blank?
    return price_points.first[:cost].to_f if price_points.size == 1

    interpolate(width, height)
  end

  def interpolate(width, height)
    points = price_points.sort_by { |p| p[:width] }

    # Find bracketing points
    r1, r2 = find_bracket(points, width)
    return points.first[:cost].to_f if r1.nil? || r2.nil?

    # Width fraction
    width_range = r2[:width].to_f - r1[:width].to_f
    frac = width_range.zero? ? 0.0 : (width - r1[:width].to_f) / width_range

    # Interpolate cost and height at this width
    interp_cost = r1[:cost].to_f + frac * (r2[:cost].to_f - r1[:cost].to_f)
    interp_height = r1[:height].to_f + frac * (r2[:height].to_f - r1[:height].to_f)

    # Height adjustment
    height_factor = (@pricing_data["height_factor"] || 0.5).to_f
    if interp_height > 0
      height_adj = 1 + height_factor * (@height - interp_height) / interp_height
    else
      height_adj = 1.0
    end

    @method = :interpolated
    (interp_cost * height_adj).round(2)
  end

  def find_bracket(points, width)
    # Exact match
    exact = points.find { |p| p[:width].to_f == width }
    return [exact, exact] if exact

    # Below minimum (extrapolate)
    if width < points.first[:width].to_f
      return [points[0], points[1]]
    end

    # Above maximum (extrapolate)
    if width > points.last[:width].to_f
      return [points[-2], points[-1]]
    end

    # Between two points
    points.each_cons(2) do |a, b|
      return [a, b] if width >= a[:width].to_f && width <= b[:width].to_f
    end

    [nil, nil]
  end

  def sum_upcharges
    # Upcharges come from product.specs JSONB — the option configurator
    # renders these as selects with data-upcharge attributes.
    # selected_options is a hash like { "lift_style" => "motorized_wand", ... }
    # We need to look up each selected option's upcharge from specs.
    return 0.0 if @selected_options.blank?

    specs = @product.specs || {}
    total = 0.0

    @selected_options.each do |key, value|
      upcharge = find_upcharge(specs, key, value)
      total += upcharge if upcharge
    end

    total
  end

  def find_upcharge(specs, key, value)
    # specs structure: { "lift_styles" => [{ "name" => "cordless", "upcharge" => 0 }, ...] }
    # The key in selected_options is singular (lift_style), specs key is plural (lift_styles)
    specs_key = pluralize_spec_key(key)
    options = specs[specs_key]
    return nil unless options.is_a?(Array)

    option = options.find { |o| o["name"] == value }
    option ? option["upcharge"].to_f : 0.0
  end

  def pluralize_spec_key(key)
    # lift_style → lift_styles, mount_type → mount_types, upgrade → upgrades, warranty → warranty_options
    case key
    when "lift_style" then "lift_styles"
    when "mount_type" then "mount_types"
    when "upgrade" then "upgrades"
    when "warranty" then "warranty_options"
    else key.to_s
    end
  end

  def fetch_markup
    # Uses the existing MarkupSetting system at /admin/settings/margins
    # Default 0.40 (40%), with per-manufacturer and per-category overrides
    MarkupSetting.effective_markup_for(@product)
  end

  def pricing_data
    @pricing_data ||= @product.pricing || {}
  end

  def price_points
    @price_points ||= (pricing_data["price_points"] || []).map(&:with_indifferent_access)
  end
end
```

### MarkupSetting Integration

The existing markup settings page (`/admin/settings/margins`) stores global default markup, with optional per-manufacturer and per-category overrides. The `PricingCalculator` calls `MarkupSetting.effective_markup_for(product)` which resolves:

1. If a manufacturer-specific override exists → use that
2. If a category-specific override exists → use that
3. Otherwise → global default (0.40)

If `MarkupSetting` doesn't have this method yet, add it:
```ruby
def self.effective_markup_for(product)
  mfr_override = find_by(target_type: "Manufacturer", target_id: product.manufacturer_id)
  return mfr_override.value if mfr_override

  cat_override = find_by(target_type: "ProductCategory", target_id: product.product_category_id)
  return cat_override.value if cat_override

  global_default || 0.40
end
```

---

## Quote Form UX Changes

### What Amanda Sees (Client-Facing Quote Build)

```
Manufacturer:  [SelectBlinds ▼]
Product:       [Cordless Light Filtering Cellular Shades ▼]
               ┌─────────────────────────────┐
               │ LIFT STYLE: [cordless ▼]     │
               │ MOUNT TYPE: [inside ▼]       │
               │ UPGRADE:    [None ▼]         │
               │ WARRANTY:   [3yr ▼]         │
               └─────────────────────────────┘
Color:         [swatch grid — filtered to product]
Location:      [Living Room - north - 1]
Width:  [ 48 ]   Height: [ 54 ]   Quantity: [ 2 ]
               ┌─────────────────────────────┐
               │  Client Price: $389.94      │
               │  ($194.97 each)             │
               └─────────────────────────────┘
Discount: [None ▼]  Value: [   ]  Reason: [          ]
Notes:    [                                                          ]
```

**No cost fields visible.** No "What Amanda pays." No unit_cost input. The client price box updates live as dimensions, options, or quantity change.

### What Gets Hidden

From `app/views/admin/quote_line_items/_form.html.erb`:
- Remove the "Unit Cost ($)" field and its helper text ("What Amanda pays")
- Remove the "Unit Price ($)" field and its helper text ("What client pays")
- Replace both with a read-only "Client Price" display that auto-calculates
- Keep `unit_cost` and `unit_price` as hidden fields set by the calculator

### Override Field

Below the dimensions row, add an optional "Verified Cost" field:
- Label: "Verified Cost (optional)"
- Helper text: "Only if you have an exact price from the vendor. Overrides auto-calculation."
- When empty: calculator interpolates from price points
- When filled: calculator uses this as the base cost instead
- Show a small "Manual" badge next to the client price when override is active

### Stimulus Controller Changes

The existing `quote_calculator_controller.js` needs to:
1. Send width, height, and selected_options to the PricingCalculator
2. Two options:
   - **Option A (client-side):** Port the interpolation logic to JS. Fetch product pricing JSON on product select. Compute everything in the browser. No server round-trip. Faster.
   - **Option B (server-side):** POST to a new endpoint `/admin/quotes/:id/quote_line_items/calculate` with width, height, product_id, selected_options. Returns JSON with the price breakdown. Slightly slower but keeps logic in Ruby (DRY with server-side calculation).

**Recommendation: Option A (client-side).** The interpolation is simple math. The product's pricing JSONB can be sent along with the `product-search:selected` event detail (already sends specs). The Stimulus controller already has all the inputs it needs. No network round-trip means instant updates as Amanda types dimensions.

The server-side `PricingCalculator` still exists — it runs on save (controller create/update) to compute the final `unit_cost` and `unit_price` that get stored. The client-side JS is a preview; the Ruby service is the source of truth.

### Updated quote_calculator_controller.js

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["unitCost", "unitPrice", "quantity", "costPreview",
                    "width", "height", "overrideCost", "priceDisplay",
                    "upchargeTotal"]

  connect() {
    this._pricingData = null
    this._selectedOptions = {}
    this._markup = parseFloat(this.element.dataset.quoteCalculatorMarkupValue || "0.40")
  }

  // Called when product is selected (listens for product-search:selected)
  loadPricing(event) {
    this._pricingData = event.detail.pricing || null
    this._specs = event.detail.specs || null
    this.calculate()
  }

  // Called when option configurator updates
  configure(event) {
    if (event?.detail?.options) {
      this._selectedOptions = event.detail.options
    }
    this.calculate()
  }

  calculate() {
    const width = parseFloat(this.widthTarget?.value) || 0
    const height = parseFloat(this.heightTarget?.value) || 0
    const quantity = parseInt(this.quantityTarget?.value) || 1
    const override = parseFloat(this.overrideCostTarget?.value) || null

    if (width === 0 || height === 0) {
      this.priceDisplayTarget.innerHTML = '<p class="text-sm text-gray-400">Enter dimensions to see price.</p>'
      return
    }

    if (!this._pricingData && !override) {
      this.priceDisplayTarget.innerHTML = '<p class="text-sm text-gray-400">Select a product to see price.</p>'
      return
    }

    // Apply mount type dimension adjustments
    const { adjWidth, adjHeight, mountNote } = this._applyMountAdjustments(width, height)

    const baseCost = override || this._interpolate(adjWidth, adjHeight)
    const upcharges = this._sumUpcharges()
    const unitCost = baseCost + upcharges
    const unitPrice = unitCost * (1 + this._markup)
    const lineTotal = unitPrice * quantity

    // Store in hidden fields for form submission
    if (this.hasUnitCostTarget) this.unitCostTarget.value = unitCost.toFixed(2)
    if (this.hasUnitPriceTarget) this.unitPriceTarget.value = unitPrice.toFixed(2)

    // Update display
    this.priceDisplayTarget.innerHTML = `
      <div class="text-2xl font-bold text-theme-500">$${lineTotal.toFixed(2)}</div>
      <p class="text-sm text-gray-400">$${unitPrice.toFixed(2)} each</p>
      ${mountNote ? `<p class="text-xs text-gray-400 mt-1">${mountNote}</p>` : ''}
      ${override ? '<span class="inline-block mt-1 text-xs bg-amber-100 text-amber-700 px-2 py-0.5 rounded">Manual price</span>' : ''}
    `
  }

  _applyMountAdjustments(width, height) {
    const mountType = this._selectedOptions?.mount_type
    if (!mountType || !this._specs) return { adjWidth: width, adjHeight: height, mountNote: null }

    const mountOptions = this._specs.mount_types || []
    const mount = mountOptions.find(m => m.name === mountType || m === mountType)
    if (!mount || typeof mount === "string") return { adjWidth: width, adjHeight: height, mountNote: null }

    const wAdj = mount.width_adjustment || 0
    const hAdj = mount.height_adjustment || 0
    const adjWidth = width + wAdj
    const adjHeight = height + hAdj
    const mountNote = (wAdj > 0 || hAdj > 0)
      ? `Outside mount: +${wAdj}" width, +${hAdj}" height`
      : null
    return { adjWidth, adjHeight, mountNote }
  }

  _interpolate(width, height) {
    const points = (this._pricingData?.price_points || []).slice().sort((a, b) => a.width - b.width)
    if (points.length === 0) return 0
    if (points.length === 1) return points[0].cost

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

    const widthRange = r2.width - r1.width
    const frac = widthRange === 0 ? 0 : (width - r1.width) / widthRange
    const interpCost = r1.cost + frac * (r2.cost - r1.cost)
    const interpHeight = r1.height + frac * (r2.height - r1.height)

    const heightFactor = this._pricingData.height_factor || 0.5
    const heightAdj = interpHeight > 0
      ? 1 + heightFactor * (height - interpHeight) / interpHeight
      : 1.0

    return interpCost * heightAdj
  }

  _sumUpcharges() {
    // Upcharges come from the option-configurator selects
    // Each select has data-upcharge attribute on the selected option
    let total = 0
    document.querySelectorAll("[data-option-configurator-target='field']").forEach(sel => {
      const opt = sel.selectedOptions[0]
      if (opt && opt.dataset.upcharge) {
        total += parseFloat(opt.dataset.upcharge)
      }
    })
    return total
  }
}
```

---

## Product Admin Pricing Section

### File: `app/views/admin/products/_form.html.erb`

Add a "Pricing Reference Points" section to the product edit form. Pre-populated with standard U.S. window sizes — the user just fills in the cost for each size from the vendor's website.

```erb
<%# Pricing reference points — standard window sizes %>
<div class="border-t border-gray-200 pt-6 mt-6" data-controller="product-pricing">
  <h3 class="text-lg font-semibold text-theme-500 mb-2">Pricing Reference Points</h3>
  <p class="text-sm text-gray-500 mb-4">
    Enter the vendor's price for each standard window size.
    Leave blank if the vendor doesn't offer that size.
    The system interpolates between these for non-standard sizes.
  </p>

  <div data-product-pricing-target="container" class="space-y-2">
    <!-- Standard sizes rendered as rows, pre-populated: -->
    <!-- Width [24] × Height [36] = $[   ]  Kitchen/bath        [Remove] -->
    <!-- Width [28] × Height [44] = $[   ]  Bedroom             [Remove] -->
    <!-- Width [28] × Height [52] = $[   ]  Bedroom             [Remove] -->
    <!-- Width [32] × Height [48] = $[   ]  Common mid-size     [Remove] -->
    <!-- Width [36] × Height [48] = $[   ]  Very common         [Remove] -->
    <!-- Width [36] × Height [60] = $[   ]  Most common DH      [Remove] -->
    <!-- Width [48] × Height [48] = $[   ]  Sliding/picture     [Remove] -->
    <!-- Width [48] × Height [60] = $[   ]  Living room         [Remove] -->
    <!-- Width [60] × Height [60] = $[   ]  Large               [Remove] -->
    <!-- Width [72] × Height [48] = $[   ]  Wide/sliding        [Remove] -->
  </div>

  <button type="button" data-action="click->product-pricing#addPoint"
          class="mt-3 text-sm text-theme-500 hover:text-theme-400 font-medium">
    + Add custom size
  </button>

  <div class="mt-4 grid grid-cols-2 gap-4">
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">Height Factor</label>
      <input type="number" step="0.1" min="0" max="1" value="0.5"
             name="product[pricing][height_factor]"
             class="w-full rounded-lg border-gray-300 ...">
      <p class="text-xs text-gray-400 mt-1">
        0 = width only. 0.5 = half the height ratio. 1 = proportional to height.
      </p>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">Last Verified</label>
      <input type="date" name="product[pricing][last_verified]" value="<%= Date.current %>"
             class="w-full rounded-lg border-gray-300 ...">
    </div>
  </div>
</div>
```

The standard sizes are pre-populated as rows with width/height locked (read-only). Only the cost field is editable. Rows with blank costs are excluded from the saved JSONB. "Add custom size" lets the user add a non-standard size if needed.

### Stimulus: `product_pricing_controller.js`

A new controller that manages the dynamic price-point rows and assembles the JSONB structure on submit.

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "heightFactor", "lastVerified"]

  connect() {
    this._pointCount = 0
  }

  addPoint() {
    // Append a new row: Width [] × Height [] = $[] [Remove]
    const row = document.createElement("div")
    row.className = "flex items-center gap-2"
    row.innerHTML = `
      <input type="number" placeholder="Width" name="product[pricing][price_points][][width]"
             class="w-20 rounded-lg border-gray-300 ...">
      <span class="text-gray-400">×</span>
      <input type="number" placeholder="Height" name="product[pricing][price_points][][height]"
             class="w-20 rounded-lg border-gray-300 ...">
      <span class="text-gray-400">=</span>
      <div class="relative">
        <span class="absolute left-2 top-1/2 -translate-y-1/2 text-gray-400">$</span>
        <input type="number" step="0.01" placeholder="0.00" name="product[pricing][price_points][][cost]"
               class="w-24 rounded-lg border-gray-300 pl-5 ...">
      </div>
      <button type="button" data-action="click->product-pricing#removePoint"
              class="text-red-400 hover:text-red-600 text-sm">Remove</button>
    `
    this.containerTarget.appendChild(row)
  }

  removePoint(event) {
    event.currentTarget.closest(".flex").remove()
  }
}
```

### Controller: `Admin::ProductsController#product_params`

Already permits `pricing: {}`. No change needed — the nested hash structure (price_points array, height_factor, last_verified) is captured by the existing `pricing: {}` permit.

---

## Tasks

### Task 1: Add override_cost migration + permit

**Files:**
- Create: `db/migrate/XXXXXXXX_add_override_cost_to_quote_line_items.rb`
- Modify: `app/controllers/admin/quote_line_items_controller.rb`

**Steps:**
1. Generate migration: `bin/rails generate migration AddOverrideCostToQuoteLineItems override_cost:decimal`
2. Edit migration to add precision/scale: `add_column :quote_line_items, :override_cost, :decimal, precision: 8, scale: 2`
3. Run: `bin/rails db:migrate`
4. Add `:override_cost` to `line_item_params` permit array
5. Run rubocop
6. Commit

### Task 2: Create PricingCalculator service

**Files:**
- Create: `app/services/pricing_calculator.rb`
- Create: `test/services/pricing_calculator_test.rb`

**Steps:**
1. Write failing tests for interpolation (use the 4 SelectBlinds data points, leave-one-out)
2. Write failing test for override_cost path
3. Write failing test for no-pricing-data path (returns 0)
4. Write failing test for upcharge summing
5. Implement PricingCalculator per spec above
6. Add `MarkupSetting.effective_markup_for(product)` if it doesn't exist
7. Run tests, verify all pass
8. Run rubocop
9. Commit

### Task 3: Integrate PricingCalculator into quote_line_items controller

**Files:**
- Modify: `app/controllers/admin/quote_line_items_controller.rb`

**Steps:**
1. In `create` action, before save: if product_id present and width/height present, run PricingCalculator and set `unit_cost` and `unit_price` on the line item (unless override_cost is blank — then override_cost is the base_cost)
2. Same for `update` action
3. Remove manual `unit_cost` / `unit_price` from form params — they're computed server-side now
4. Run rubocop
5. Commit

### Task 4: Update quote line item form — hide cost, show client price

**Files:**
- Modify: `app/views/admin/quote_line_items/_form.html.erb`
- Modify: `app/javascript/controllers/quote_calculator_controller.js`

**Steps:**
1. Remove the "Unit Cost ($)" and "Unit Price ($)" visible fields
2. Add hidden `unit_cost` and `unit_price` fields (for form submission)
3. Add "Verified Cost (optional)" field below dimensions
4. Add "Client Price" display box (read-only, styled prominently)
5. Add width/height targets to quote-calculator controller
6. Update product_search_controller to include `pricing` and `specs` in the `selected` event detail (alongside existing `id` and `specs`). Also update `/admin/products/search` JSON endpoint to include `pricing` in the response.
7. Update quote_calculator to: listen for product-search:selected (get pricing + specs data), listen for option-configurator:updated (get selected options), recalculate on width/height/quantity/override/mount-type change
8. Port interpolation logic to JS (mirror of Ruby PricingCalculator)
9. Apply mount type dimension adjustments before interpolation
10. Update price display live — show mount adjustment note when outside mount is selected
11. Add markup value as data attribute on the form element (from MarkupSetting)
12. Verify in browser
13. Commit

### Task 5: Add pricing section to product admin form

**Files:**
- Create: `app/models/standard_window_size.rb` (constant — standard sizes array)
- Modify: `app/views/admin/products/_form.html.erb`
- Create: `app/javascript/controllers/product_pricing_controller.js`

**Steps:**
1. Create `StandardWindowSize` module with the 10 key reference sizes:
   ```ruby
   module StandardWindowSize
     SIZES = [
       { width: 24, height: 36, label: "Kitchen / Bath" },
       { width: 28, height: 44, label: "Bedroom" },
       { width: 28, height: 52, label: "Bedroom" },
       { width: 32, height: 48, label: "Common mid-size" },
       { width: 36, height: 48, label: "Very common" },
       { width: 36, height: 60, label: "Most common double-hung" },
       { width: 48, height: 48, label: "Sliding / Picture" },
       { width: 48, height: 60, label: "Living room" },
       { width: 60, height: 60, label: "Large" },
       { width: 72, height: 48, label: "Wide / Sliding" }
     ].freeze
   end
   ```
2. Add "Pricing Reference Points" section to product form, pre-populated with SIZES
3. Create product_pricing_controller with addPoint/removePoint
4. Render existing price_points from product.pricing JSONB (fill in costs for sizes already researched)
5. Blank cost rows excluded on save
6. Verify: edit a product, add costs for standard sizes, save, reload — data persists
7. Commit

### Task 6: Seed pricing data for existing SelectBlinds products

**Files:**
- Modify: `db/seeds.rb` or create: `db/seeds/pricing_data.rb`

**Steps:**
1. For each of the 4 SelectBlinds products, populate `pricing` JSONB with:
   - `price_points` array using the StandardWindowSize::SIZES format
   - `height_factor`: 0.5
   - `last_verified`: "2026-07-19"
   - `verified_by`: "Mason"
2. Use the 4 known price points for Cordless Light Filtering Cellular Shades:
   24x36=$71.99, 36x48=$146.99, 60x60=$243.99, 72x48=$254.99
   (other standard sizes left blank — to be filled when Mason researches them)
3. For the other 3 products, leave price_points empty with a note in `pricing: { "needs_research": true }`
4. Run the seed update via rails runner (not destructive db:seed)
5. Verify pricing data loads in quote form (client price auto-calculates for the 4 known sizes)
6. Commit

### Task 7: Update quote show page — hide cost in presentation mode

**Files:**
- Modify: `app/views/admin/quotes/show.html.erb`

**Steps:**
1. The existing "Reveal Margins" PIN-gated view already hides costs by default
2. Verify the cost/margin section only shows after PIN unlock
3. Verify the client-facing quote view (Client::Quotes) shows retail-only pricing
4. Fix any gaps where cost data leaks into presentation mode
5. Commit

### Task 8: Browser end-to-end verification

**Steps:**
1. Start dev server
2. Log in as admin
3. Navigate to quote → add line item
4. Select manufacturer → product → verify swatches load
5. Enter width/height → verify client price auto-calculates
6. Change options (motorized, etc.) → verify price updates
7. Enter override cost → verify price switches to manual
8. Save line item → verify it persists with correct unit_cost and unit_price
9. View quote show page → verify costs are PIN-gated
10. View client quote view → verify only retail prices shown
11. Commit any fixes

---

## Edge Cases

### No pricing data on product
- Calculator returns `method: :no_pricing`, cost = 0
- Quote form shows: "Pricing not configured for this product. Enter a verified cost or add price points in Products."
- Amanda can use the override_cost field as a fallback

### Only 1 reference point
- Calculator uses that point's cost directly, no interpolation
- Height adjustment still applies if height differs
- Form shows: "Only 1 price point — estimates will be rough"

### Size outside reference range (extrapolation)
- Calculator extrapolates (uses nearest two points, extends the line)
- Form shows a small warning indicator: "⚠ Size outside reference range — estimate may vary"
- Amanda can enter a verified cost for unusual sizes

### Product with no specs (no options)
- Upcharges = 0
- Calculator still works — just base cost + markup

### Quote with no dimensions
- Calculator can't compute (needs width + height)
- Form shows: "Enter dimensions to see price"
- Amanda can still save with override_cost if she has a flat price

### Vendor raises prices
- Amanda edits the product, updates price_points, sets new last_verified date
- All future quotes use the new pricing
- Existing quotes keep their stored unit_cost/unit_price (snapshot at quote time)

---

## Future Improvements (Not Built Now)

1. **Pricing staleness dashboard** — widget showing products with `last_verified` older than 90 days
2. **Bilinear grid interpolation** — if accuracy needs improvement, support a proper W×H grid of reference points for true bilinear interpolation
3. **Price curve preview** — on the product admin page, show a chart of the interpolation curve so Amanda can see how estimates vary by size
4. **Automatic price refresh** — scrape vendor sites for current prices (requires per-vendor scrapers, fragile, deferred)
5. **Multi-vendor comparison** — "same size, different vendors" side-by-side cost comparison for Amanda's purchasing decisions
