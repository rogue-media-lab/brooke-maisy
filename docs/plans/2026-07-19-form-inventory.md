# Brooke & Maisy Legal Forms — Complete Inventory

## 7 Documents Covering Full Project Lifecycle

### 1. Design & Installation Services Agreement (6 pages)
**Purpose:** Master contract between Brooke & Maisy and client.
**Fields to auto-fill:**
- Effective Date
- Client Name
- Project Location
**Legal text:** 23 sections (scope, fees, deposit, change orders, timeline, cancellation rights, return policy, site access, permits, materials, IP, photos, warranties, insurance, liability, indemnification, notices, liens, dispute resolution, governing law, general provisions)
**Signature blocks:** Client (signature, print name, date) + Designer (signature, date, print name: Amanda Nelson, Owner)

### 2. Notice of Cancellation (2 pages, two copies)
**Purpose:** SC legal requirement — 3-day right to cancel.
**Fields to auto-fill:**
- Date of Transaction
- Client Name
- Project Location
- Cancellation deadline date (3 business days after transaction date)
**Legal text:** Standard FTC Cooling-Off Rule notice (cancel within 3 business days, property returned within 10 business days, goods available for pickup)
**Contact info:** Brooke & Maisy, Attn: Amanda Nelson, 1726 Gold Hill Rd., #1071, Fort Mill, SC 29708, amanda@brookenmaisy.com, (817) 807-5219
**Signature block:** Client signature + date (only if cancelling)
**Note:** Two copies required by SC/federal law.

### 3A. Work Order — CLIENT Version (2 pages)
**Purpose:** Itemized scope of work and pricing for the client.
**Page 1 fields:**
- Client Name
- Date
- Project Location
- Project Contact Phone / Email
- Estimated Start Date
- Estimated Completion Date
- Scope of Work (freeform text — describe rooms and scope)
- Products table: Room | Product/Item | Qty | Unit Price | Line Total (8 rows)

**Page 2 fields:**
- Subtotal
- Tax
- Total Project Price
- Design Retainer Due at Signing (%)
- Deposit Due Before Ordering (%)
- Balance Due at Completion
- Client Signature + Date
- Designer Signature + Date

**Approval text:** "By signing below, Client approves the products, pricing, and scope of work described in this Work Order, subject to the terms of the Design & Installation Services Agreement."

### 3B. Work Order — INTERNAL Version (2 pages)
**Purpose:** Internal tracking with measurements, cost data, and site notes.
**Page 1 fields:**
- Client Name
- Date
- Project Location
- Project Contact Phone / Email
- Estimated Start Date
- Estimated Completion Date
- Subcontractor / Installer (if applicable)
- Measurements table: Room | Product/Item | Width | Height | Qty | Install Notes

**Page 2 fields:**
- Supplier / Vendor Cost (materials)
- Labor / Installation Cost
- Markup Applied (%)
- Client-Facing Total (from client Work Order)
- Estimated Margin
- Site & Access Notes (access instructions, pets, gate codes, parking, HOA restrictions, hazards)
- Internal Notes (freeform)

**Header:** "INTERNAL USE ONLY — Do not share with Client. Contains measurements and cost details."

### 4. Change Order (2 pages)
**Purpose:** Amends the Work Order when scope changes.
**Fields to auto-fill:**
- Change Order #
- Date
- Client Name
- Project Location
- Original Work Order Date
- Changes table: Description of Change | Reason for Change | Cost Impact (+/-)
- Original Contract Price
- Net Change This Order
- Revised Contract Price
- Original Estimated Completion Date
- Revised Estimated Completion Date
- Amount Due Now + Due Date
**Signature blocks:** Client + Designer (both with date)

### 5. Project Completion & Sign-Off (2 pages)
**Purpose:** Final walkthrough, warranty start, final payment authorization.
**Fields to auto-fill:**
- Client Name
- Project Location
- Walkthrough Date
- Final Walkthrough Checklist: Room | Item/Task | Status | Notes
- Outstanding Items (freeform)
- Total Contract Price (including approved Change Orders)
- Total Paid to Date
- Final Balance Due + Due Date
**Warranty text:** "Client acknowledges that the one (1) year labor warranty described in Section 14 of the Agreement begins on the Walkthrough Date..."
**Signature blocks:** Client + Designer (both with date)

### 6. Invoice (2 pages)
**Purpose:** Billing document.
**Header:** Brooke & Maisy Interior Designs, LLC, 1726 Gold Hill Rd., #1071, Fort Mill, SC 29708, amanda@brookenmaisy.com, (980) 277-0709
**Fields to auto-fill:**
- Bill To (name, address)
- Project Location
- Invoice #
- Invoice Date
- Payment Due Date
- Related Work Order / Change Order #
- Line Items table: Room | Description | Qty | Unit Price | Line Total
- Subtotal
- Tax
- Less: Deposits / Prior Payments Received
- Balance Due
**Payment instructions:** "Brooke & Maisy Interior Designs, LLC accepts payment by cash, check, or credit card. Checks payable to Amanda Nelson..."

## Auto-Fill Data Mapping

| Form Field | Database Source |
|---|---|
| Client Name | `Client.display_name` |
| Client Address | `Client.address` |
| Project Location | `Quote.client.address` or `Project.address` |
| Date / Effective Date | `Time.current` |
| Transaction Date | `Quote.created_at` or contract signing date |
| Cancellation Deadline | Transaction date + 3 business days |
| Scope of Work | `Quote.quote_line_items` grouped by room/location |
| Products table (client) | Line items: room, product name, qty, unit_price, line_total |
| Measurements table (internal) | Line items: room, product name, width, height, qty, install notes |
| Subtotal | `QuoteCalculator[:subtotal]` |
| Tax | `QuoteCalculator[:tax_amount]` |
| Total Project Price | `QuoteCalculator[:grand_total]` |
| Design Retainer | `Quote.deposit_percentage` or 50% default |
| Deposit | `QuoteCalculator[:deposit_amount]` |
| Balance Due | `QuoteCalculator[:balance_due]` |
| Supplier Cost (internal) | `QuoteCalculator[:total_cost]` |
| Markup Applied (internal) | `QuoteCalculator` markup rate (manufacturer override or 40%) |
| Estimated Margin (internal) | `QuoteCalculator[:gross_profit]` / `[:profit_margin_pct]` |
| Estimated Start/Completion | `Project` dates (manual or estimated) |
| Business Info | Hardcoded constants |
| Signature Lines | Left blank for signing |
| Invoice # | Sequential, generated on demand |
| Change Order # | Sequential, generated on demand |
