# Tech Installer Dashboard

**Branch:** `feature/tech-installer-dashboard`
**Started:** 2026-07-14

## The Problem
Mason and David are out doing an install. Had to call Kate for the address, forgot the hand broom. Installers need a mobile-friendly screen with the job address, a map, and an equipment checklist — without bugging Kate or Amanda.

## The Solution
A new `tech` role with its own invite-only login and a minimal, mobile-first dashboard. Two tabs: **Job** (address + map) and **Checklist** (equipment list).

---

## Pieces

### 1. User Model — Add `tech` Role
- Add `tech` to the existing role enum: `{ client: "client", tech: "tech", admin: "admin" }`
- Same Devise flow — invite-only, no self-registration, admin creates the user
- `scope :techs, -> { where(role: "tech").order(:name) }`

### 2. ChecklistItem Model (New)
Minimal model for the shared equipment checklist:
- `name:string` — "hand broom", "cordless drill", "ladder", "hardware kit"
- `position:integer` — drag-friendly ordering
- `active:boolean` (default true) — soft-delete for retired items
- `scope :active, -> { where(active: true).order(:position) }`
- Admin CRUD at `/admin/checklist_items` with sidebar link

### 3. Tech Namespace — Auth & Routing
- `Tech::BaseController` — `before_action :authenticate_user!` + `require_tech` (redirect to root unless `current_user.tech?`)
- `Tech::DashboardController#show` — the single screen techs see
- Minimal layout — no admin chrome, no public navbar. Just a header with "Sign out" and the content.
- Routes:
  ```ruby
  namespace :tech do
    root "dashboard#show"
  end
  get "tech-portal", to: redirect("/tech")
  ```

### 4. Tech Dashboard — Mobile-First, Two Tabs
**Tab 1 — Job:**
- Project address (from `Project.address`)
- Embedded Leaflet map via OpenStreetMap (free, no API key)
- Client name
- "Open in Maps" link → Google Maps directions

**Tab 2 — Checklist:**
- Active checklist items as a simple tap-to-check list
- Check state is session-only (not persisted) — "did I load the truck?"
- "Reset" button to uncheck all

**Tab implementation:** Simple radio-button toggle pattern or Stimulus controller. No heavy JS — two `<button>` elements that show/hide divs.

**Mobile design:** 
- Full-width, no side padding waste
- Large tap targets (44px minimum)
- Readable on a phone in sunlight
- Map takes the top half of the Job tab, address and directions below

### 5. Admin — Manage Techs & Checklist
- **Tech users:** Extend admin Clients controller to support `tech` role when creating/inviting users. Add a "Techs" filter or separate section.
- **Checklist items:** Full CRUD at `/admin/checklist_items` — add, edit, reorder, deactivate. Sidebar link under "Manage."

### 6. Authorization (Pundit)
- `Tech::DashboardPolicy` — only techs can view
- `ChecklistItemPolicy` — admin manages, tech reads
- ApplicationController layout resolver: add `tech` layout for the tech namespace

---

## Open Question
**Project selection**: Which project does the tech see?

Options:
- **A) Project list** — tech sees all active projects, taps one (simplest, most flexible)
- **B) Assigned projects** — admin assigns projects to techs (structured, more work)
- **C) Latest project** — just shows the most recent project (brittle)

**Recommendation: A for MVP.** Tech sees a list of active projects → taps one → sees the Job/Checklist tabs. We can add assignment later.

---

## Build Order
1. Add `tech` role to User model + scope + policy update
2. Create `ChecklistItem` model + migration + admin CRUD
3. Create `Tech::BaseController` + layout + auth
4. Build `Tech::DashboardController` + views (tabs, map, checklist)
5. Wire routes + admin sidebar link
6. Seed some checklist items
7. Test locally, push, deploy

## Files Touched
- `app/models/user.rb` — role enum
- `app/models/checklist_item.rb` — new
- `db/migrate/XXXXXX_create_checklist_items.rb` — new
- `app/controllers/tech/base_controller.rb` — new
- `app/controllers/tech/dashboard_controller.rb` — new
- `app/views/tech/dashboard/show.html.erb` — new
- `app/views/layouts/tech.html.erb` — new
- `app/policies/checklist_item_policy.rb` — new
- `app/policies/tech/dashboard_policy.rb` — new
- `app/controllers/admin/checklist_items_controller.rb` — new
- `app/views/admin/checklist_items/` — new (index, new, edit, _form)
- `app/views/admin/shared/_sidebar.html.erb` — add link
- `app/controllers/admin/clients_controller.rb` — optional: support tech role
- `config/routes.rb` — tech namespace + admin checklist_items
- `app/controllers/application_controller.rb` — optional: tech layout
- `db/seeds.rb` — seed checklist items