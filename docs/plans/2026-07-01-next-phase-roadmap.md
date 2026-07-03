# Brooke & Maisy — Next Phase Roadmap

## Immediate (this week)

### 1. Merge design presentation builder
- Branch: `feature/design-presentation-builder` → `main`
- Run migrations on production
- Deploy via GitHub CI to Heroku
- **Commit:** `fa0bc1c feat: add design presentation models and migrations (Phase 0)`

### 2. Client-side presentation view
- Clients can see published design presentations in their portal
- Route: `/client/projects/:id` — add "Design Presentation" tab/section
- Pundit: `DesignPresentationPolicy#show?` allows when `published?`
- Render mood boards (with images), product selections, color swatches

---

## Data-Driven Content (replace hardcoded pages)

### 3. About page content management
- **Current:** Static `pages#about` view — hardcoded bio, philosophy, approach
- **Need:** `AboutContent` model or simple key/value settings (e.g. `SiteSetting` model: key, value, updated_at)
  - Bio text, mission statement, approach text, profile photo
  - Or a lightweight `RichText` model for editable content blocks
- **Admin:** Edit form at `/admin/settings` or inline on about page preview
- **Public:** `@about = SiteSetting.about_content` — dynamic rendering

### 4. Services — hardcoded → admin-managed
- **Current:** 3 static service cards on `/services` and home page (duplicated hardcoded content)
- **Model:** `Service` — title, description, icon_name (SVG identifier), bullet_points (text array), display_order (integer), active (boolean)
- **Admin:** `/admin/services` — CRUD with reorder
- **Sidebar:** "Services" link under Manage
- **Public:** `pages#services` + home page section → `Service.active.ordered`
- **Seed:** Migrate the 3 existing hardcoded services (Full Home Redesign, Room Makeover, Color & Styling)

### 5. Trade Network — hardcoded → admin-managed
- **Current:** 182-line static page with 4 fake trade partners, dead "+ Add Trade" button, fake filter buttons
- **Model:** `TradePartner` — name, trade_type (painter/carpenter/electrician/plumber/other), phone, email, website, description, years_experience, rating (decimal), jobs_referred (integer), active (boolean), display_order
- **Admin:** `/admin/trade_partners` — CRUD
- **Sidebar:** "Trade Network" link under Manage
- **Public:** `pages#trade_network` → `TradePartner.active.ordered`, filter by type

---

## Square Integration (business operations)

### 6. Square API integration
- Pull invoices, appointments, and contracts into the B&M client portal
- Amanda uses Square for payments/scheduling — surface that data inside B&M
- Client sees: project timeline + Square invoices + upcoming appointments in one dashboard
- Requires Square developer account + API key

---

## Creative Differentiators

### 7. AI Room Visualizer
- Gemini 2.5 Flash Image ("nano-banana")
- Upload room photo → apply curated palette + product selections → AI-generated visualization
- Run async via Solid Queue (already configured)
- Free tier: 500 images/day

### 8. Hermes read-only API
- 6 endpoints: clients, projects, messages, stats
- Bearer token auth
- Plan doc exists: `docs/plans/2026-06-23-hermes-read-api.md`
- Enables Slack/Discord integration for Amanda

---

## Polish & Automation

### 9. Email automation
- Project status change → notify client
- Design presentation published → notify client
- Questionnaire submitted → notify Amanda
- New message from contact form → notify Amanda
- Uses existing Gmail SMTP config

---

## Notes
- Trade Network and Services are quick wins (1-2 hrs each) — pure CRUD with existing patterns
- About content could be a simple key/value SiteSetting model or a lightweight CMS block
- The design presentation builder is the highest-value item to deploy — it's already built, just needs merge + client view