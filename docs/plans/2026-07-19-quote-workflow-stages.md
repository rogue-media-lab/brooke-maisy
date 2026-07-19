# Quote Workflow Stages — Implementation Plan

> **For Hermes:** Build incrementally. Each phase is independently shippable.

**Goal:** Transform the quote system from a single form into a guided 3-stage workflow (Measure → Product → Sell) with 7 process steps. Amanda walks a client through on an iPad, left to right, with a visual stepper showing progress.

**Branch:** `feature/quote-workflow-stages` (from `feature/quote-inventory-system`)

**Tech Stack:** Rails 8, Stimulus, ActiveStorage, Tailwind, Prawn (PDF generation)

---

## The 3 Stages and 7 Processes

```
STAGE 1: MEASURE          STAGE 2: PRODUCT         STAGE 3: SELL
┌─────────────────┐       ┌─────────────────┐      ┌─────────────────┐
│ 1. Client Info  │       │ 3. Product       │      │ 4. Quote        │
│ 2. Measurements │───→   │    Choices       │───→  │ 5. Contract     │
│                 │       │                  │      │ 6. Cancellation  │
│                 │       │                  │      │ 7. Payment      │
└─────────────────┘       └─────────────────┘      └─────────────────┘
```

### What Exists

| Process | Status | Notes |
|---------|--------|-------|
| 1. Client Info | ✅ Built | Client model, inline creation, admin CRUD |
| 2. Measurements | ✅ Partial | Room/Window models, location field, dimensions on line items. Missing: photo capture, room layout visual |
| 3. Product Choices | ✅ Built | Product search, manufacturer filter, swatch picker, option configurator, mount adjustments, live pricing |
| 4. Quote | ✅ Built | PricingCalculator, quote show page, deposit breakdown, sort options. Missing: Preview template (broken) |
| 5. Contract | ❌ Not built | SC home improvement contract + e-signature |
| 6. Cancellation | ❌ Not built | SC Notice of Cancellation form (legal requirement) |
| 7. Payment | ❌ Not built | Simple payment log — deposit collected, amount, date, method. No Square API. |

---

## Phase 1: Tab UI Framework + Stage Stepper

**Goal:** Create a dedicated quote workflow layout with a visual stepper at the top. Amanda sees where she is in the process at all times.

### Architecture

A new layout `app/views/layouts/quote_workflow.html.erb` replaces the admin sidebar layout when Amanda is working on a quote. The sidebar collapses to a hamburger menu or a thin icon strip. The stepper shows all 7 processes with the current one highlighted.

```
┌──────────────────────────────────────────────────────────────────────┐
│  Brooke & Maisy        [≡]                              Amanda R.    │
├──────────────────────────────────────────────────────────────────────┤
│  ● Client → ● Measure → ○ Product → ○ Quote → ○ Contract → ○ Cancel → ○ Pay │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                    [ Current step content ]                          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

- ● = completed (green)
- ○ = not yet started (gray)
- Current step is highlighted (theme color)

### Quote Status Machine

Add a `workflow_stage` enum to Quote that tracks progress through the 7 steps:

```ruby
enum :workflow_stage, {
  client_info: 0,      # Stage 1: Measure
  measurements: 1,     # Stage 1: Measure
  product_choices: 2,  # Stage 2: Product
  quote_review: 3,     # Stage 3: Sell
  contract: 4,         # Stage 3: Sell
  cancellation: 5,     # Stage 3: Sell
  payment: 6,          # Stage 3: Sell
  completed: 7
}, default: :client_info
```

This is separate from the existing `status` enum (draft/sent/approved/declined/ordered). The `status` tracks the quote's business state; `workflow_stage` tracks Amanda's progress through the workflow.

### Files

- Create: `app/views/layouts/quote_workflow.html.erb`
- Create: `app/views/admin/quotes/_stepper.html.erb` (partial)
- Modify: `app/controllers/admin/quotes_controller.rb` (use workflow layout for show/edit)
- Create: migration to add `workflow_stage` to quotes

### Tasks

1. Add `workflow_stage` enum + migration to Quote
2. Create `quote_workflow.html.erb` layout — full-width, no sidebar, stepper at top, hamburger menu for admin navigation
3. Create `_stepper.html.erb` partial — renders the 7-step progress bar, highlights current stage
4. Update QuotesController#show to use workflow layout, pass `workflow_stage` to stepper
5. Wire stepper links — each step navigates to the relevant section/action
6. Verify on browser — iPad-width viewport, stepper visible, navigation works

---

## Phase 2: Photo Capture on Measurements

**Goal:** Amanda takes photos during the measurement walk-through. Each photo is labeled and attached to a room or window. Photos serve three purposes: installer reference, client portal display, future AI mockup source.

### Photo Model

```ruby
class Photo < ApplicationRecord
  belongs_to :room, optional: true
  belongs_to :window, optional: true
  belongs_to :quote, optional: true  # can be on the quote directly if no room yet

  has_one_attached :image

  enum :kind, {
    measurement: 0,    # raw photo of the window/room during measure
    installer: 1,      # reference photo for installers
    reference: 2,      # finished room mockup (future AI generation)
    progress: 3        # during installation
  }, default: :measurement

  validates :label, presence: true
end
```

### iPad Photo Capture

On the iPad, Amanda uses the device camera to take a photo. HTML `<input type="file" accept="image/*" capture="environment">` opens the camera directly. The photo uploads via ActiveStorage Direct Upload (already configured for Cloudflare R2 — bypasses Heroku timeout).

### Measurement Walk-Through View

A new view at `/admin/quotes/:id/measurements` that shows:
- List of rooms (created during this stage)
- For each room: room name, dimensions, and a photo grid
- "Add photo" button per room/window — opens camera on iPad
- Label field per photo (e.g., "Living Room - north window")
- Quick-add room button (creates a Room record on the fly)

### Files

- Create: `app/models/photo.rb`
- Create: migration for photos table
- Create: `app/controllers/admin/quote_measurements_controller.rb`
- Create: `app/views/admin/quote_measurements/show.html.erb`
- Modify: stepper to link measurements step to this view

### Tasks

1. Create Photo model + migration
2. Create QuoteMeasurementsController — shows rooms, handles photo uploads
3. Create measurements view — room list, photo grid per room, camera capture input
4. Add ActiveStorage direct upload for photos (bypass Heroku timeout)
5. Wire stepper "Measurements" link to the measurements view
6. Verify on browser — photo upload works, labels persist, photos display in grid

---

## Phase 3: Fix Preview Button

**Goal:** The Preview button on the quote show page is broken — the controller action exists but the template doesn't. This is a quick win that makes the quote presentable to clients.

### What's Needed

The `Admin::QuotesController#preview` action calls `QuoteCalculator.new(@quote).calculate` and renders with `layout: "admin"`. The template `app/views/admin/quotes/preview.html.erb` needs to be created.

The preview should show:
- Quote header (client name, quote number, date, valid until)
- Line items table with product, dimensions, quantity, unit price, line total
- Deposit and balance summary
- No admin chrome, no edit buttons, no cost data
- Print-friendly (existing print CSS should apply)

### Files

- Create: `app/views/admin/quotes/preview.html.erb`
- Modify: `app/controllers/admin/quotes_controller.rb` (use quote_workflow layout, not admin)

### Tasks

1. Create preview template — clean, client-facing, retail-only pricing
2. Update controller to use workflow layout
3. Verify print CSS works (hide nav, stepper, buttons)
4. Verify no cost/margin data leaks

---

## Phase 4: Contracts, Forms + E-Signature

**Goal:** Generate all 7 legal forms as PDFs with auto-filled data. Client signs on the iPad with a drawn signature — no DocuSign, no SaaS fees.

### The 7 Forms

All forms documented in `docs/plans/2026-07-19-form-inventory.md`. Each is recreated in Prawn with the exact legal language from the original PDFs, with blank fields auto-filled from the database.

| Form | Auto-Fill Source | Signature |
|------|-----------------|-----------|
| Design & Installation Services Agreement | Client name, date, project location | Client + Designer |
| Notice of Cancellation (2 copies) | Transaction date, client name, project location, deadline | Client only (if cancelling) |
| Work Order — CLIENT | Full quote data: products, pricing, deposit schedule | Client + Designer |
| Work Order — INTERNAL | Measurements, cost tracking, site notes | None (internal) |
| Change Order | Original pricing, change details, revised pricing | Client + Designer |
| Completion Sign-Off | Walkthrough checklist, final balance, warranty date | Client + Designer |
| Invoice | Line items, subtotal, tax, deposits, balance due | None |

### PDF Generation

Use the `prawn` gem. Each form gets its own service object:

- `app/services/pdf/agreement_pdf.rb` — Design & Installation Services Agreement
- `app/services/pdf/cancellation_pdf.rb` — Notice of Cancellation (renders 2 copies)
- `app/services/pdf/work_order_client_pdf.rb` — Client work order
- `app/services/pdf/work_order_internal_pdf.rb` — Internal work order
- `app/services/pdf/change_order_pdf.rb` — Change order
- `app/services/pdf/completion_signoff_pdf.rb` — Completion sign-off
- `app/services/pdf/invoice_pdf.rb` — Invoice

Each service takes a Quote (or Project for post-contract forms) and returns a PDF string. The legal text is hardcoded as constants — never paraphrased, copied verbatim from the source PDFs.

### E-Signature: Drawn Signature Capture

Uses the `signature_pad` JavaScript library (~12KB, no dependencies). Client draws their signature on the iPad screen with a finger or Apple Pencil.

**Flow:**
1. Amanda generates the contract PDF (blank signature lines)
2. Client portal shows the contract on screen with a signature canvas below
3. Client draws signature on the canvas + types print name + checks "I agree"
4. System captures the canvas as a PNG image
5. Records audit data: `signed_at` timestamp, `signed_name` (typed), `signature_ip` (request IP)
6. Prawn re-renders the PDF with the signature PNG placed at the signature line coordinates via `image(x, y, image_data)`
7. The signed PDF saves as an ActiveStorage attachment on the quote
8. Amanda signs the same way (designer signature line)

**Legal validity:** ESIGN Act (federal) + SC UETA require: (a) attribution — they drew it, (b) intent — "I agree" checkbox, (c) audit trail — timestamp + IP + typed name. All three captured.

**Files:**
- Add: `signature_pad` npm package (or vendor the JS directly)
- Create: `app/javascript/controllers/signature_pad_controller.js` — wraps the library, captures PNG data
- Create: `app/javascript/controllers/signature_controller.js` — orchestrates the full signing flow (show form, capture signature, submit to server)
- Create: `app/views/clients/signatures/new.html.erb` — client-facing signing page
- Create: `app/controllers/clients/signatures_controller.rb` — receives signature data, re-renders PDF, saves attachment

### Signature Data Model

Migration adds to `quotes`:
```ruby
# Client signature
add_column :quotes, :client_signed_at, :datetime
add_column :quotes, :client_signed_name, :string
add_column :quotes, :client_signature_ip, :string
add_column :quotes, :client_signature_image, :text  # base64 PNG data, or use ActiveStorage

# Designer signature
add_column :quotes, :designer_signed_at, :datetime
add_column :quotes, :designer_signed_name, :string

# Contract status
add_column :quotes, :contract_sent_at, :datetime
add_column :quotes, :contract_signed_pdf, :string  # ActiveStorage attachment
```

Or use a separate `Signature` model if the same quote needs multiple form signatures (agreement, change orders, completion sign-off all need signatures at different times):

```ruby
class Signature < ApplicationRecord
  belongs_to :quote
  belongs_to :signable, polymorphic: true  # Quote, ChangeOrder, CompletionSignOff

  has_one_attached :signature_image  # the drawn PNG

  enum :signer, { client: 0, designer: 1 }
  enum :document_type, {
    agreement: 0,
    work_order: 1,
    change_order: 2,
    completion_signoff: 3,
    cancellation: 4
  }

  validates :signed_at, presence: true
  validates :signed_name, presence: true
  validates :signature_ip, presence: true
end
```

### Files

- Add: `prawn` gem to Gemfile
- Add: `signature_pad` JS library (vendored or npm)
- Create: 7 PDF service objects (one per form)
- Create: `app/controllers/admin/quote_documents_controller.rb` — generate/download forms
- Create: `app/controllers/clients/signatures_controller.rb` — client signing flow
- Create: `app/controllers/admin/quote_contracts_controller.rb` — send contract, track status
- Create: `app/views/admin/quote_documents/index.html.erb` — form generation dashboard
- Create: `app/views/clients/signatures/new.html.erb` — client signing page
- Create: `app/javascript/controllers/signature_pad_controller.js`
- Create: `app/javascript/controllers/signature_controller.js`
- Create: migration for signature fields (Signature model or columns on quotes)
- Modify: stepper to link contract + cancellation steps
- Modify: client portal to show signing status

### Tasks

1. Add prawn gem, create base PDF layout (header, footer, branding)
2. Create AgreementPdfGenerator — the 6-page master contract (verbatim legal text)
3. Create CancellationPdfGenerator — two copies of the notice
4. Create WorkOrderClientPdfGenerator — client-facing scope + pricing
5. Create WorkOrderInternalPdfGenerator — measurements + cost tracking
6. Create InvoicePdfGenerator — billing document
7. Create ChangeOrderPdfGenerator (future — when change order workflow is built)
8. Create CompletionSignOffPdfGenerator (future — when project completion is built)
9. Add signature_pad JS library + Stimulus controller
10. Create Signature model + migration
11. Create client signing flow — show form, draw signature, submit, re-render PDF with embedded signature
12. Create admin document dashboard — generate any form, download, send to client
13. Wire stepper contract + cancellation + payment links
14. Verify: generate each form with real data from Quote #2 (Bob Ross)
15. Verify: client signing flow on iPad-width viewport

---

## Phase 5: Payment Status Tracking

**Goal:** Log payment status without Square API integration. Amanda uses her physical Square terminal, then records the payment in the app.

### Payment Model

```ruby
class Payment < ApplicationRecord
  belongs_to :quote

  enum :method, {
    square_terminal: 0,
    check: 1,
    cash: 2,
    bank_transfer: 3,
    other: 4
  }, default: :square_terminal

  enum :kind, {
    deposit: 0,
    balance: 1,
    partial: 2
  }, default: :deposit

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_at, presence: true
end
```

### Payment View

A simple view at `/admin/quotes/:id/payment` that shows:
- Grand total (from QuoteCalculator)
- Deposit amount (50% by default)
- Balance due
- List of recorded payments (amount, date, method, kind)
- "Record payment" form — amount, date, method dropdown, kind (deposit/balance/partial)
- Status indicator: "Deposit outstanding" → "Deposit collected, balance due" → "Paid in full"

No Square API. Amanda processes the card on her terminal, then logs it here.

### Files

- Create: `app/models/payment.rb`
- Create: migration for payments table
- Create: `app/controllers/admin/quote_payments_controller.rb`
- Create: `app/views/admin/quote_payments/show.html.erb`
- Modify: stepper to link payment step

### Tasks

1. Create Payment model + migration
2. Create QuotePaymentsController — show payments, record new payment
3. Create payment view — summary, payment list, record form
4. Calculate balance: grand_total - sum(payments)
5. Wire stepper payment link
6. Verify payment recording updates balance display

---

## Phase 6: Quote Show Page Integration

**Goal:** Wire all the pieces together on the quote show page. The stepper links to each stage's view. The show page becomes the hub.

### What Changes

The existing `admin/quotes/show.html.erb` becomes the "Quote Review" step (process 4). It shows the full quote with line items, totals, and deposit breakdown — what we already built. The stepper at the top links to:

1. Client Info → existing client show/edit
2. Measurements → `/admin/quotes/:id/measurements` (Phase 2)
3. Product Choices → existing quote line items management
4. Quote Review → existing quote show page
5. Contract → `/admin/quotes/:id/contract` (Phase 4)
6. Cancellation → `/admin/quotes/:id/cancellation` (Phase 4)
7. Payment → `/admin/quotes/:id/payment` (Phase 5)

### Tasks

1. Add stepper partial to quote show page
2. Wire each stepper link to the correct route
3. Update workflow_stage as Amanda progresses through steps
4. Verify full flow: create quote → add client → take measurements → add products → review quote → generate contract → record payment

---

## What We're NOT Building (Deferred)

- Google Calendar integration — manual client entry for now
- Square API payment processing — physical terminal + manual log
- AI reference image generation — photo capture foundation is built, AI layer deferred
- Drag-and-drop floor plan editor — room layout visual deferred, location field serves as interim
- Change order workflow — form template built in Phase 4, but the interactive change order creation flow deferred (needs its own model + controller)
- Completion sign-off workflow — form template built in Phase 4, but the walkthrough checklist UI deferred (needs project phase tracking)
- DocuSign or paid e-signature SaaS — self-hosted signature_pad covers the legal requirements at $0

---

## Build Order

1. **Phase 1** — Tab UI + stepper (foundation, ~2 hours)
2. **Phase 3** — Fix Preview button (quick win, ~30 min)
3. **Phase 2** — Photo capture (measurable value for Amanda, ~3 hours)
4. **Phase 5** — Payment tracking (simple, ~2 hours)
5. **Phase 4** — All 7 forms + e-signature (most complex, ~6-8 hours)
6. **Phase 6** — Integration (wires it all together, ~1 hour)

Total estimated: ~15-17 hours of focused work.

---

## Potential Gaps to Consider

These aren't blocking the build but worth thinking about:

1. **Email delivery of signed contracts** — the existing QuoteMailer sends quote notifications. Contract signing should trigger an email to both Amanda and the client with the signed PDF attached. Low effort — extend the existing mailer.

2. **Client portal auth for signing** — the client needs to be logged in to sign. The existing Devise invite-only portal handles this, but the signing page needs to be scoped properly (Client:: namespace, Pundit policy).

3. **Contract versioning** — if Amanda changes the quote after the contract is signed, the signed PDF is stale. Need a rule: once signed, the quote is locked (status changes from draft to ordered/contracted). Changes require a Change Order.

4. **Business info consistency** — the forms reference two different phone numbers: (980) 277-0709 in the agreement, (817) 807-5219 in the cancellation notice. Should confirm which is current before building the PDF templates.

5. **Print fallback** — if the iPad signature flow fails (battery dead, screen broken), Amanda needs to print the blank PDF, get a wet signature, and scan it back in. The system should support uploading a signed PDF as a fallback to the drawn signature flow.
