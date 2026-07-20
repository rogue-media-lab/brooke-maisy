# Quote & Inventory System — Implementation Plan

**Date:** 2026-07-12
**Status:** Planning — not yet built
**Decision:** Solatech Focus declined — building in-house
**Reference Manufacturers:** SelectBlinds, Horizons Window Fashions, Solatech vendor products

---

## Problem Statement

Amanda needs to quote window treatments to clients during or immediately after consultations. The product landscape is complex:

- Multiple manufacturers (SelectBlinds, Horizons, Hunter Douglas, Graber, and dozens more)
- Radically different product types (cellular shades, roller shades, roman shades, drapes, shutters, motorized blinds)
- Each product type has its own option matrix: cell sizes, lift styles, mount types, motorization
- Each product has its own color/fabric/material palette — from 15 options (SelectBlinds cellular) to 600+ (Horizons fabric gallery)
- No public APIs or data feeds from any of these manufacturers
- Amanda needs to build quotes in front of clients, in under 5 minutes, showing retail pricing only

The functional target is what Solatech Focus does: measure → configure → quote → close → order. But we're building it into the Brooke-Maisy Rails app, integrated with the existing project/client/design-presentation system.

---

## Strategic Approach: Two-Tier Product Entry

### Tier 1 — "Easy In" (Products From Active Jobs)
When Amanda is working a real client job, she already knows the exact product:
- Manufacturer + product name + URL
- Key specs (type, material, the specific color the client chose)
- Wholesale cost + retail price (she knows what she charges)
- One photo
- ~2 minutes to enter during the quoting workflow

These products get added on the fly. They're battle-tested — real products for real clients.

### Tier 2 — "Research Entry" (Catalog Building)
Products Amanda researches ahead of time to build her sellable catalog:
- All available options, colors, specifications
- Multiple images and swatches
- Pricing tiers if available
- Detailed notes on use cases, lead times, limitations
- ~10-15 minutes to research and enter

This builds the catalog over time. One piece at a time. The system grows with the business.

### Tier 3 — "Bulk Import" (Scraped/Extracted)
For manufacturers with large swatch galleries (Horizons: 600+ colors across 4 product lines):
- Scrape swatch names, categories, color ranges, and images from manufacturer sites
- Import as `Swatch` records linked to products
- Amanda doesn't need all 600 in the system — just the ones she's likely to quote
- But she needs the ABILITY to pull any swatch in seconds when a client asks

---

## Architecture Overview

```
Project
  ├─ has_many :rooms
  │   └─ has_many :windows        (measurements — width, height, mount, notes, photo)
  ├─ has_many :quotes
  │   ├─ has_many :quote_line_items
  │   │   ├─ belongs_to :product (optional)
  │   │   ├─ belongs_to :window  (optional)
  │   │   └─ belongs_to :swatch  (optional — selected color/material)
  │   ├─ has_many :revisions     (versioning after send)
  │   └─ belongs_to :promo_code  (optional)
  ├─ has_many :design_presentations (existing)
  └─ has_many :purchase_orders     (Phase 4)

Product
  ├─ belongs_to :manufacturer
  ├─ belongs_to :product_category
  ├─ has_many :product_swatches
  ├─ has_many :swatches, through: :product_swatches
  ├─ specs:jsonb    (type, cell_size, lift_styles, mount_types, dimensions, constraints — with upcharges)
  ├─ images:jsonb   ([{url, alt, kind: "room|detail|product|swatch|diagram"}])
  ├─ videos:jsonb   ([{url, platform: "youtube|vimeo", video_id, title, kind: "installation|overview|how-to"}])
  ├─ documents:jsonb ([{url, title, kind: "installation|measurement|warranty|spec_sheet|certification"}])
  └─ pricing:jsonb  (base_cost, suggested_retail, pricing_tiers if applicable)

Swatch
  ├─ belongs_to :manufacturer
  ├─ name, hex (approximate)
  ├─ category (blackout, light_filtering, sheer, solid, pattern_print, liner)
  ├─ color_range (whites, blues, beiges, etc.)
  ├─ image_url
  └─ has_many :product_swatches
  └─ has_many :products, through: :product_swatches

Manufacturer       (standalone reference)
ProductCategory    (self-referential tree)
PromoCode          (coupon codes with validation rules)
```

**Why Swatch is its own model:**
The Horizons site showed 600+ colors across product lines. A single color ("Aegean") might be available on multiple product styles. Storing colors as a JSONB array on Product means duplicating "Aegean" across every product it touches. A separate Swatch model means it lives once, linked via a join table. It also enables: bulk import from manufacturer sites, search across all swatches, and "available in these colors" queries per product.

---

## The Full Pricing Math

Every quote line item runs through this chain:

```
BASE COST (what Amanda pays manufacturer for standard config)
  + option_upcharges (double cell +$30, motorized +$150, TDBU +$45)
  = CONFIGURED COST

CONFIGURED COST × quantity
  = TOTAL_COST (Amanda's outlay for this line)

TOTAL_COST × (1 + markup_rate)
  = SUGGESTED_RETAIL

SUGGESTED_RETAIL − line_item_discount
  = ADJUSTED_RETAIL

LINE TOTAL = ADJUSTED_RETAIL × quantity

───────────────────────────────────────
QUOTE TOTALS:
SUM(all line_totals) = SUBTOTAL
SUBTOTAL − quote_discount = ADJUSTED_SUBTOTAL
ADJUSTED_SUBTOTAL × tax_rate = TAX_AMOUNT
ADJUSTED_SUBTOTAL + TAX_AMOUNT = GRAND_TOTAL (client pays)

PROFIT:
GRAND_TOTAL − SUM(all total_costs) = GROSS_PROFIT
GROSS_PROFIT / GRAND_TOTAL × 100 = PROFIT_MARGIN_PCT
```

### Important: Markup ≠ Margin

| Term | Formula | Example ($100 cost, $140 retail) |
|---|---|---|
| **Markup** | (price − cost) / cost × 100 | ($140 − $100) / $100 = **40% markup** |
| **Margin** | (price − cost) / price × 100 | ($140 − $100) / $140 = **28.6% margin** |

Amanda likely thinks in markup ("I multiply my cost by 1.4"). The admin dashboard shows both numbers so there's no confusion. The settings page labels it "Markup %" with a parenthetical: "($100 cost × 1.4 = $140 retail = 28.6% margin)."

### Markup Hierarchy (Resolution Order)

Amanda sets margins at `/admin/settings/margins`:

1. **Default markup:** 40% (applied to all products unless overridden)
2. **Category override:** Cellular shades 35%, Drapery 50%
3. **Manufacturer override:** SelectBlinds 40%, Horizons 45%

Resolution: manufacturer override > category override > default. Changing margins only affects future quotes — sent quotes are locked.

### Discount Types

| Type | Scope | Example |
|---|---|---|
| Line item % | Single product | "10% off this shade" |
| Line item $ | Single product | "$25 off" |
| Quote % | Entire subtotal | "15% friends & family" |
| Quote $ | Entire subtotal | "$500 off whole job" |
| Promo code | Quote (predefined) | `SUMMER25` = 25% off, min $500 purchase |

Discounts apply AFTER markup. The discount comes out of Amanda's margin, not the manufacturer's cost.

### Tax

- Default rate from `SiteSetting` (SC: 6% state + local)
- Per-quote override (different jurisdictions, tax-exempt clients)
- Tax applied to adjusted subtotal (after quote-level discounts)

---

## Models — Detailed Schema

### Room (Phase 1)
```
project_id:integer
name:string          (Living Room, Master Bedroom, Kitchen)
position:integer
notes:text
```

### Window (Phase 1)
```
room_id:integer
name:string          (North wall — large, Above kitchen sink)
width:decimal        (inches, 2 decimal places for fractions)
height:decimal
mount_type:string    (inside, outside)
depth:decimal        (window frame depth — matters for inside mount)
notes:text           (obstructions, trim style, casing notes)
position:integer
has_one_attached :photo  (Active Storage — photo of the actual window)
```
**Critical:** Amanda measures ONCE and quotes multiple products per window. This model prevents re-entry.

### Manufacturer
```
name:string
website:string
trade_program_url:string
trade_discount:decimal  (Amanda's trade discount % if applicable)
markup_override:decimal (e.g., 0.45 = 45% markup on all products from this manufacturer)
notes:text
```

### ProductCategory
```
name:string
slug:string
parent_id:integer     (self-referential: Window Treatments > Roller Shades > Blackout)
spec_template:string  (which YAML config to use for the spec form)
markup_override:decimal (e.g., 0.35 = 35% markup on all products in this category)
```

### Product
```
manufacturer_id:integer
product_category_id:integer
name:string
description:text
product_url:string
unit:string            (per window, per panel, per foot)
specs:jsonb            (type, options with upcharges, dimensions, constraints — the flexible part)
pricing:jsonb          ({base_cost: 89.00, suggested_retail: 140.00, tiers: [...]})
images:jsonb           ([{url, alt, kind: "room|detail|product|swatch|diagram"}])
videos:jsonb           ([{url, platform: "youtube|vimeo", video_id, title, kind: "installation|overview|how-to"}])
documents:jsonb        ([{url, title, kind: "installation|measurement|warranty|spec_sheet|certification"}])
lead_time_days:integer
is_active:boolean
tier:integer           (1 = easy-in, 2 = research, 3 = bulk-import)
notes:text
```

**Note on warranty:** The `warranty:string` field from earlier drafts has been removed. Warranty is an upsell with tiers (e.g., 3-year free, 5-year +$9.43, unlimited +$18.87) and lives in `specs:jsonb` → `warranty_options` alongside other upcharge options. This keeps pricing logic in one place.

**Note on size-based pricing:** SelectBlinds base prices vary by window dimensions — a 24"×36" cellular shade is $71.99, but a 48"×60" costs more. For Phase 1-2, Amanda enters the unit cost manually for the size she's quoting. A `pricing:jsonb` structure with size tiers (e.g., `[{max_sqft: 20, cost: 89.00}, {max_sqft: 40, cost: 129.00}]`) is deferred to Phase 5. The `QuoteCalculator` can be extended to look up size-based cost without changing its interface.

#### Media Strategy (Why These Are Separate JSONB Columns)

A SelectBlinds product page contains 6 images of different kinds, 2 YouTube installation videos, and 3 downloadable PDFs (installation guide, measurement worksheet, motorization instructions). Storing these as separate JSONB columns — rather than one big `attachments` array — keeps queries targeted and the quote builder fast:

- **`images:jsonb`** — Pulled for the product gallery and swatch picker. Always needed during quoting. **Visible to both admin and client.**
- **`videos:jsonb`** — Embedded in the admin "Tech Info" tab on the product detail page. Installation videos, product overviews, how-to guides. **Admin-only** — clients hire Brooke & Maisy for installation, they don't need to see how it's done.
- **`documents:jsonb`** — Linked as downloads in the Tech Info tab. Measurement worksheets, warranty PDFs, spec sheets. **Admin-only** reference material. Selected documents (e.g., warranty info) can be attached to client-facing quote emails at Amanda's discretion.

All three grow organically as Amanda researches products: an image from the manufacturer site, a YouTube install video she found, a PDF spec sheet she downloaded. Each gets a `kind` tag so the UI can display them in the right context without Amanda manually sorting.

**Admin Product Detail — Tab Layout:**
```
[Overview] [Specs & Options] [Tech Info] [Pricing]
```
The Tech Info tab houses videos and documents. Images live on Overview. Specs & Options renders the configurator preview. Pricing shows base cost, upcharges, and markup.

#### specs JSONB — Example (Horizons Roller Shade)
```json
{
  "type": "roller_shade",
  "product_style": "shades_of_elegance_roller",
  "categories": ["blackout", "light_filtering", "room_darkening", "semi_sheer", "sheer"],
  "mount_types": ["inside", "outside"],
  "min_width": 12,
  "max_width": 144,
  "min_height": 12,
  "max_height": 144,
  "motorization_available": true,
  "motorization_max_width": 120,
  "constraints": {
    "inside_mount": {"min_depth": 1.5},
    "motorized": {"max_sqft": 24}
  }
}
```

#### specs JSONB — Example (SelectBlinds Cellular Shade — with upcharges)

From the actual SelectBlinds product page. Note how each option carries its own upcharge:

```json
{
  "type": "cellular",
  "cell_size": "3/4\" honeycomb",
  "lift_styles": [
    {"name": "cordless", "upcharge": 0},
    {"name": "motorized_wand", "upcharge": 87.17},
    {"name": "automation", "upcharge": 121.18}
  ],
  "mount_types": ["inside", "outside", "no_drill"],
  "no_drill_upcharge": 28.00,
  "upgrades": [
    {"name": "automation_extension_cable", "upcharge": 7.81, "requires": "automation"},
    {"name": "automation_bridge", "upcharge": 155.78, "requires": "automation"}
  ],
  "warranty_options": [
    {"name": "3_year_limited", "upcharge": 0},
    {"name": "5_year_limited", "upcharge": 9.43},
    {"name": "5_year_unlimited", "upcharge": 18.87}
  ],
  "min_width": 13,
  "max_width": 84,
  "min_height": 12,
  "max_height": 84,
  "width_increment": "1/8\"",
  "height_increment": "1/8\"",
  "headrail_depths": {"cordless": 1.875, "cord_loop": 2.125},
  "constraints": {
    "cordless": {"min_inside_depth": 1.25, "flush_depth": 2.25},
    "motorized": {"max_sqft": 24}
  }
}
```

### Swatch (color/material — shared across products)
```
manufacturer_id:integer
name:string              (Aegean, Bone, Billy Goat)
hex:string               (approximate — #4A90D9)
category:string          (blackout, light_filtering, sheer, solid, pattern_print, liner)
color_range:string       (whites_offwhites, aquas_blues, beiges_browns, etc.)
image_url:string
is_new:boolean
is_active:boolean
```

### ProductSwatch (join table)
```
product_id:integer
swatch_id:integer
```

### Quote
```
project_id:integer
client_id:integer        (denormalized)
promo_code_id:integer    (optional)
status:integer           (draft, sent, viewed, approved, declined, ordered)
version_number:integer   (increments on each send)
subtotal:decimal
quote_discount_type:string  (percentage, fixed)
quote_discount_value:decimal
quote_discount_reason:string
adjusted_subtotal:decimal
tax_rate:decimal
tax_amount:decimal
grand_total:decimal
deposit_percentage:decimal  (e.g., 50 = 50% due at order)
deposit_amount:decimal
balance_due:decimal
valid_until:date
notes:text
sent_at:datetime
approved_at:datetime
```

### QuoteRevision
```
quote_id:integer
version_number:integer
snapshot:jsonb           (frozen copy of line items at time of send)
created_at:datetime
```
When Amanda edits a quote that's already been sent, the old version is snapshotted. Client always sees the latest sent revision.

### QuoteLineItem
```
quote_id:integer
product_id:integer       (optional — can quote without a catalog product)
window_id:integer        (optional — links to measured window)
swatch_id:integer        (optional — selected color/material)
description:string       (fallback when no product linked)
width:decimal            (from window, or freehand if no window linked)
height:decimal
quantity:integer         (default 1)
selected_options:jsonb   ({cell_size: "double", lift_style: "cordless", mount: "inside"})
unit_cost:decimal        (what Amanda pays)
unit_price:decimal       (retail to client)
discount_type:string     (percentage, fixed, nil)
discount_value:decimal
discount_reason:string
line_total:decimal
status:integer           (proposed, approved, declined — defaults to proposed)
position:integer
notes:text               (client wants to match kitchen remodel color, etc.)
```

**Quote → Purchase Order handoff:** When a client approves a quote, individual line items can have mixed statuses — they might approve 3 of 5 items. Only line items with `status: approved` flow into PurchaseOrders. Amanda can mark items approved/declined from the admin quote view. This bridges the gap between "client said yes" and "place the order."

### PromoCode
```
code:string              (SUMMER25, WELCOME100)
discount_type:string     (percentage, fixed)
discount_value:decimal
min_purchase:decimal     (optional — must spend at least $X)
expires_at:date          (optional)
usage_limit:integer      (optional — max number of uses)
usage_count:integer
is_active:boolean
```

### PurchaseOrder (Phase 4)
```
manufacturer_id:integer
quote_id:integer
status:integer           (draft, submitted, confirmed, shipped, received)
order_date:date
expected_delivery:date
actual_delivery:date
notes:text
```

### PurchaseOrderLineItem (Phase 4)
```
purchase_order_id:integer
quote_line_item_id:integer
product_id:integer
quantity:integer
unit_cost:decimal
total_cost:decimal
manufacturer_sku:string
status:integer
```

---

## QuoteCalculator Service Object

All pricing math lives in one place. Testable in isolation.

```ruby
# app/services/quote_calculator.rb
class QuoteCalculator
  def initialize(quote)
    @quote = quote
  end

  def calculate
    {
      line_items: calculate_line_items,
      subtotal: subtotal,
      quote_discount: quote_discount,
      adjusted_subtotal: adjusted_subtotal,
      tax_amount: tax_amount,
      grand_total: grand_total,
      total_cost: total_cost,
      gross_profit: gross_profit,
      profit_margin_pct: profit_margin_pct,
      deposit_amount: deposit_amount,
      balance_due: balance_due
    }
  end

  private

  def calculate_line_items
    @quote.quote_line_items.map do |item|
      configured_cost = item.unit_cost
      suggested_retail = configured_cost * (1 + markup_rate_for(item))
      adjusted_retail = apply_line_discount(suggested_retail, item)
      {
        id: item.id,
        configured_cost: configured_cost,
        suggested_retail: suggested_retail,
        adjusted_retail: adjusted_retail,
        line_total: adjusted_retail * item.quantity
      }
    end
  end

  def markup_rate_for(item)
    # Resolution: manufacturer override > category override > default
    product = item.product
    return Setting.default_markup unless product

    manufacturer_rate = product.manufacturer.markup_override
    category_rate = product.product_category.markup_override

    manufacturer_rate || category_rate || Setting.default_markup
  end

  # ... subtotal, tax, profit, etc.
end
```

This is called on every quote save and whenever Amanda views the quote. Turbo Streams push updated numbers to the DOM without a page reload.

---

## The Quote Builder UX (Amanda's Flow)

Amanda is sitting with a client. She opens her iPad or laptop.

```
1. Project → "New Quote"
2. Sees rooms/windows already measured (from Phase 1 room/window setup)
3. For a window, clicks "Add Product" →
   Search-as-you-type dropdown (Stimulus controller) of product catalog
4. Picks product → option configurator loads (driven by product.specs JSONB)
   - Cell size: [Single] [Double]
   - Lift style: [Cordless] [Continuous Cord] [Motorized]
   - Color: swatch grid with images (from linked Swatch records)
   - Mount: [Inside] [Outside]
5. Real-time price updates as she configures (Turbo Stream replacing totals card)
6. Can override price: "This client gets a deal" → manually adjust unit_price
7. Can add discount: "10% off this item" → selects reason from dropdown or types
8. Adds to quote → line item appears below with running totals
9. Repeats for each window
10. Optional: applies quote-level discount or promo code
11. Clicks "Preview Client View" → sees exactly what client will see (NO costs, retail only)
12. Sends: email via portal, or prints PDF, or shares screen
```

**Target: under 5 minutes for a standard 5-window quote.**

### Stimulus Controllers for the Quote Builder

| Controller | Purpose |
|---|---|
| `product_search_controller` | Search-as-you-type product picker. Debounced fetch against `/admin/products/search?q=`. |
| `option_configurator_controller` | Reads `product.specs` JSON, renders the right fields. Cell size select, lift style radios, color swatch grid. |
| `quote_calculator_controller` | Watches for changes (quantity, price, discount). Fires Turbo Stream to recalculate totals. |
| `swatch_picker_controller` | Grid of color swatches with images. Click to select, visual highlight. |

### Client View (What The Customer Sees)

Same quote, different permissions. Pundit-scoped:

```
Client sees:              Admin sees (additionally):
- Room name               - Unit cost per item
- Window name             - Total cost (Amanda's outlay)
- Product name + image    - Gross profit
- Selected options        - Profit margin %
- Color swatch (visual)   - Markup rate applied
- Retail price per item   - Quote discount details
- Any discounts (label)   - Deposit/balance breakdown
- Subtotal
- Tax
- Grand total
- "Approve" / "Question" buttons per line item
```

Implemented as: one ERB partial, conditional columns gated by `policy(Quote).show_costs?`. No separate views to maintain.

---

## Quote Templates

For repeat jobs (3BR house = same products in different colors):

- Amanda builds a quote, clicks "Save as Template"
- Template stores: product IDs, option presets, room structure — NOT prices or client info
- Next job: "New Quote from Template" → selects template → products pre-loaded → just pick colors and enter measurements
- Templates are private to Amanda (admin-only)

Model: `QuoteTemplate` with `template_data:jsonb` storing the structure.

---

## Comparison Mode

Amanda quotes 2-3 options for the same window:

```
Master Bedroom — North Wall (48" × 60")
┌─────────────────────────────────────────────────────────┐
│ OPTION A: Good                     Retail: $189.00      │
│ Single Cell, Cordless, Crisp Sand                      │
├─────────────────────────────────────────────────────────┤
│ OPTION B: Better                   Retail: $249.00      │
│ Double Cell, Cordless, Ivory Lace                      │
├─────────────────────────────────────────────────────────┤
│ OPTION C: Best                     Retail: $449.00      │
│ Double Cell, Motorized, Moon Glow                      │
└─────────────────────────────────────────────────────────┘
```

This is a UI pattern, not a model change. Multiple QuoteLineItems for the same Window, grouped visually with a "comparison group" tag. Client can approve one and decline the others.

---

## Measurement Validation

When Amanda configures a product for a window, the system checks constraints from `product.specs.constraints`:

- Inside mount requires minimum depth: window must have ≥ 1.25" depth
- Motorized has max square footage: width × height must be ≤ 24 sq ft
- Width/height within product min/max: 48" must be within 12"–144"

Validations are warnings, not blockers. Amanda can override ("I know this window, it'll work"). But the system flags potential issues.

---

## How Rails Makes This Better

| Rails Feature | Application |
|---|---|
| **JSONB + GIN** | `specs`, `pricing`, `images`, `videos`, `documents`, `selected_options` — flexible, queryable, no schema migrations per manufacturer |
| **Turbo Streams** | Real-time quote totals, inline line item editing, add/remove items without page reload |
| **Stimulus** | Search-as-you-type product picker, dynamic option configurator, swatch grid, video player |
| **Active Record enums** | Quote status, discount types, product tiers, image/video/document kinds — type-safe, queryable |
| **Pundit scopes** | One view partial, two permission levels. `policy(Quote).show_costs?` gates cost columns. |
| **Service objects** | `QuoteCalculator` — all math in one place, tested in isolation. Upcharges pulled from `specs` JSONB. |
| **Active Storage** | Window photos, product images, swatch images. Already used in the app. |
| **Action Mailer** | Quote delivery to clients, optionally attaching measurement worksheets and install PDFs from `documents` JSONB. Already configured (Gmail SMTP). |
| **Solid Queue** | PDF generation (grover/puppeteer), swatch scraping, video thumbnail generation — background jobs |
| **ViewComponent/partials** | Same quote rendered three ways: admin (costs visible), client portal (retail only), PDF (print-optimized). Media tabs for images/videos/documents on product detail. |

---

## Phased Implementation

### Phase 1: Inventory Foundation
**Models:** Room, Window, Manufacturer, ProductCategory, Product, Swatch, ProductSwatch
**Admin:** CRUD for all, dynamic spec form (YAML config per category), swatch grid uploader
**Seeds:** Load from `docs/plans/selectblinds-product-reference.yml` — 4 fully-researched SelectBlinds products across Cellular (blackout + light filtering), Roller, and Roman categories. Each includes specs with upcharges, colors/swatches, image kind taxonomy, YouTube video IDs, and PDF document URLs. The seed script reads the YAML directly: `YAML.load_file(Rails.root.join('db/seeds/selectblinds_products.yml'))` — copying the reference file into `db/seeds/` during implementation. Additional manufacturers (Horizons) follow the same pattern.
**Sidebar:** "Inventory" section with Manufacturers, Categories, Products, Swatches

### Phase 2: Quote Engine
**Models:** Quote, QuoteLineItem, QuoteRevision, PromoCode
**Service:** QuoteCalculator
**Admin:** Quote builder with Stimulus controllers, search-as-you-type, option configurator, real-time totals
**Markup settings:** `/admin/settings/margins` with category/manufacturer overrides
**Profit dashboard:** Per-quote and per-project profitability

### Phase 3: Client Experience
**Client portal:** Quote view (retail only), approve/reject per line item
**PDF:** Print-optimized HTML view (start with `@media print`, upgrade to grover later)
**Email:** Quote delivery via Action Mailer
**Templates:** Save/load quote templates
**Comparison mode:** Grouped line items for good/better/best

### Phase 4: Purchase Orders
**Models:** PurchaseOrder, PurchaseOrderLineItem
**Workflow:** Approved items → batch → POs grouped by manufacturer → track delivery

### Phase 5: Research & Scale
**Bulk swatch import:** Scrape Horizons-style swatch galleries → Swatch records
**Product clone:** Duplicate product + adjust specs
**Analytics:** Most-quoted products, average margins, win rates

---

## What This Plan Defers

- **Payment processing** — Amanda uses Square separately. Add later if needed.
- **True inventory tracking** — Made-to-order products, no warehouse stock levels.
- **Manufacturer APIs** — None exist yet. Add `ManufacturerIntegration` if APIs appear.
- **Fabric/drapery pricing** — Different model (fabric by yard + labor). Separate phase after hard products.
- **Mobile app** — Responsive Tailwind is sufficient for iPad.
- **Multi-currency** — USD only.

---

## Open Decisions

1. **Swatch scale:** Enter all 600 Horizons colors, or just the ones Amanda actually quotes? Recommendation: seed a representative set (20 per product line), let Amanda add more on demand.

2. **Deposit tracking:** 50% at order / 50% at install is standard. Confirm with Amanda.

3. **PDF generation:** Start with print CSS (zero deps). Only add grover if Amanda needs email attachments that look professional.

4. **Quote expiration:** 30 days default. Configurable.

---

## Files Changed / Created

- This plan: `docs/plans/2026-07-12-quote-inventory-system.md`