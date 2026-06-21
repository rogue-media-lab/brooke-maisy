# Design Presentation Builder — Admin-First Implementation Plan

**Date:** 2026-06-21
**Project:** Brooke & Maisy (`RML-Brooke-Maisy/brooke-maisy`)
**Scope:** Admin builds room-segmented design presentations (mood boards, product
selections, color palettes) and publishes them to clients. v1 = admin side + publish gate.
**Status:** Planned. Not yet built.

---

## 1. Goal

Give Amanda (admin) a way to assemble a **design presentation** for a project entirely
inside the app — the digital equivalent of the binder she brings to a client meeting:
inspiration imagery (mood boards), product/furniture picks with pricing, and a paint/color
palette. She builds it in **draft**, then **publishes** it. The client sees nothing until
it is published.

This document is the build spec. A future session should be able to execute it without
re-deriving the architecture.

---

## 2. Current Codebase State (verified 2026-06-21)

Inspected against live schema `db/schema.rb` version `2026_06_18_191406` (Rails 8.1).

**Existing models (6):** `User`, `Project`, `ProjectUpdate`, `Message`,
`QuestionnaireSubmission`, `ApplicationRecord`.

**`Project` model (app/models/project.rb):**
```ruby
class Project < ApplicationRecord
  belongs_to :user
  has_many :project_updates, dependent: :destroy
  has_many_attached :photos
  enum :status, { discovery: "discovery", design: "design",
                  in_progress: "in_progress", complete: "complete" }, default: "discovery"
  validates :title, presence: true
  validates :status, presence: true
  scope :recent, -> { order(created_at: :desc) }
end
```

**CRITICAL CORRECTION vs. prior planning conversation:**
The presentation models (`MoodBoard`, `ProductSelection`, `ColorSwatch`, `MoodBoardItem`)
**DO NOT EXIST** in the codebase. A grep returned zero matches. They were only ever
discussed verbally. Therefore:

- **Phase 0 is a clean greenfield CREATE — there is NO data-migration / backfill.**
- The earlier "MoodBoardItem belongs_to :project → repoint to :mood_board" backfill concern
  is moot. Nothing to repoint. Build the final structure directly.
- "Real data" on the live site is confined to `projects`, `project_updates`, `users`,
  `messages`, `questionnaire_submissions`. This feature touches none of them. **Zero risk
  to existing data.**

---

## 3. Architecture Decisions (locked for v1)

| Decision | Ruling | Why |
|---|---|---|
| Nested inline forms (`accepts_nested_attributes_for`) | **REJECTED** | File inputs can't repopulate after a validation error → Amanda loses all picked images on one bad field. Incompatible with "build over several days." Two-tab race conditions. |
| Item CRUD pattern | **Sub-resources + Turbo Streams** | Each item is its own tiny form in a Turbo Frame. Atomic, isolated save. Append on create / replace on edit / remove on destroy. The Rails 8 / Hotwire idiom. |
| Publish gate | **Container model `DesignPresentation` with status enum** (draft/published/archived) | One publishable unit per project. Client sees only `published`. No scattered per-item visibility flags. |
| Mood board granularity | **Multiple NAMED boards per presentation** (one per room) | Interior design is room-segmented. `MoodBoardItem.category` survives as a *secondary* tag within a board (textiles/lighting/finishes). |
| Product status | **Separate axis from publication** (proposed/approved/rejected) | Publication = "is this live to client." Status = "what client thinks." A proposed product is visible once published — that's the approve/reject workflow (client side, later phase). |
| Color palette | **Build in v1** | With the sub-resource pattern established, it's the same scaffold — write the pattern once. |
| Reorder UX | **Up/down arrow buttons (`button_to` PATCH)** | 5–20 items/board → arrows fully adequate. Dependency-free, keyboard-accessible, doesn't fight Turbo DOM morphing. SortableJS deferred to a later polish phase. |
| Image upload | **Active Storage Direct Upload** (`direct_upload: true`) | Files go browser → Cloudflare R2 directly, bypassing Heroku's 30s dyno request timeout. Non-negotiable on this stack. |
| Admin builder layout | **Accordions, NOT tabs** | Don't hide draft content from Amanda while she builds. (Client side uses tabs — different audience.) |

### Accepted v1 limitation (decide consciously, documented)
**Post-publication live editing.** With a plain status flag, editing a *published*
presentation shows half-finished edits to the client instantly. **v1 rule: "once published,
unpublish → edit → republish."** Acceptable for a solo designer with few clients. Real
versioning (duplicate-published-into-new-draft on republish) is deferred — see Phase 6+.

### Deferred to later phases (YAGNI for v1)
- Per-board staged release ("show living room while master bath still drafting").
- Duplicate-as-draft / presentation versioning.
- SortableJS drag-and-drop reorder.
- Client-side approve/reject actions on products (this plan is admin-first).

---

## 4. Data Model (target schema)

```
Project (existing)
  has_many :design_presentations, dependent: :destroy

DesignPresentation                      # the publishable deliverable
  belongs_to :project
  string  :title            null: false           # e.g. "Initial Design Concept"
  string  :status           default: "draft", null: false   # draft / published / archived
  datetime:published_at
  integer :position         default: 0
  has_many :mood_boards,         dependent: :destroy
  has_many :product_selections,  dependent: :destroy
  has_many :color_swatches,      dependent: :destroy

MoodBoard                               # a ROOM grouping
  belongs_to :design_presentation
  string  :name             null: false           # "Living Room", "Master Bath"
  integer :position         default: 0
  has_many :mood_board_items, dependent: :destroy

MoodBoardItem
  belongs_to :mood_board
  string  :caption
  string  :category                               # secondary tag: "Texture", "Lighting"
  integer :position         default: 0
  has_one_attached :image

ProductSelection
  belongs_to :design_presentation
  string  :name             null: false
  text    :description
  string  :vendor
  decimal :price            precision: 10, scale: 2
  string  :product_url
  string  :room                                   # optional room tag
  string  :status           default: "proposed", null: false  # proposed/approved/rejected
  text    :client_notes
  integer :position         default: 0
  has_one_attached :image

ColorSwatch
  belongs_to :design_presentation
  string  :name             null: false           # "Versatile Gray"
  string  :hex_code         null: false           # "#B5A397"
  string  :brand                                  # "Sherwin-Williams"
  string  :finish                                 # "Matte"
  string  :room
  integer :position         default: 0
```

**Conventions on every collection model:**
```ruby
scope :ordered, -> { order(:position, :created_at) }
```
Enums string-backed (matches existing `Project`/`QuestionnaireSubmission` pattern).
Validate `presence` on the `null: false` columns. Validate `hex_code` format
(`/\A#([0-9A-Fa-f]{6})\z/`).

---

## 5. Phased Build Plan

### Phase 0 — Data model & migrations (clean create)
1. Migration: create `design_presentations` (title, status, published_at, position,
   `project_id` FK, timestamps; index on `[project_id, status]`).
2. Migration: create `mood_boards` (name, position, `design_presentation_id` FK).
3. Migration: create `mood_board_items` (caption, category, position, `mood_board_id` FK).
4. Migration: create `product_selections` (all fields above, `design_presentation_id` FK).
5. Migration: create `color_swatches` (all fields above, `design_presentation_id` FK).
6. Write all 5 model files with associations, enums, `:ordered` scope, validations.
7. Add `has_many :design_presentations, dependent: :destroy` to `Project`.
8. `bin/rails db:migrate`; confirm `schema.rb` regenerates cleanly.
   (Pitfall: if any Rails cmd errors `Database URL cannot be empty`, run `unset DATABASE_URL`.)

### Phase 1 — Admin presentation shell
- `Admin::DesignPresentationsController` (under existing `Admin::BaseController`,
  which already enforces `authenticate_user!` + `require_admin` + `layout "admin"`).
- Routes: nest under project →
  ```ruby
  namespace :admin do
    resources :projects do
      resources :design_presentations do
        resource :publication, only: [:create, :destroy]   # publish / unpublish
        resources :mood_boards do
          resources :mood_board_items
        end
        resources :product_selections
        resources :color_swatches
      end
    end
  end
  ```
- Admin opens a project → list its presentations → create a draft → open the **builder page**.
- Builder page uses **accordion sections**: Mood Boards / Product Selections / Color Palette.
- Draft/Published status badge + "Preview as client" link visible at top.

### Phase 2 — Mood boards CRUD (Turbo Streams)
- `Admin::MoodBoardsController`: create/update/destroy via Turbo Stream
  (append to list / replace card / remove).
- Up/down move buttons: `button_to` PATCH to a `move` member route (or a `position` param),
  swaps position with neighbor, re-renders the boards list frame.
- Each board renders its own nested frame for its items (Phase 3).

### Phase 3 — Mood board items + image upload
- `Admin::MoodBoardItemsController`, same Turbo-Stream sub-resource pattern.
- **Active Storage Direct Upload** (`file_field direct_upload: true`) → browser → R2,
  bypasses Heroku 30s timeout.
- Thumbnail variant `resize_to_limit: [300, 300]`, `loading: "lazy"` on `image_tag`.
- Per-item caption + category + delete. Up/down reorder within the board.

### Phase 4 — Product selections + color swatches
- `Admin::ProductSelectionsController` + `Admin::ColorSwatchesController`, same scaffold.
- Product: image (direct upload), name, description, vendor, price, product_url, room,
  status select (proposed/approved/rejected — admin can set; client actions come later).
- Swatch: colored `<div style="background-color: #hex">` preview + name/hex/brand/finish/room.
  Validate hex format. (Inline `style` is the ONE allowed exception — dynamic hex can't be a
  Tailwind class. Everything else Tailwind-only per rails-conventions.)

### Phase 5 — Publish workflow + Pundit
- `PublicationsController#create` → `presentation.update(status: "published", published_at: Time.current)`.
- `#destroy` → back to `draft`, clear `published_at`.
- `DesignPresentationPolicy`: `show? = user&.admin? || record.published?`;
  `Scope#resolve` returns admin → all, client → `where(status: "published")` joined to own projects.
  **Enforce in scope server-side, not just the view.**
- Client side (separate future plan): "Design" tab on `/client/projects/:id` renders only
  published presentations; mood board grid w/ existing lightbox; swatch row; product cards.

### Phase 6+ — Later, only if requested
- SortableJS drag reorder. Per-board staged release. Duplicate-as-draft versioning.
- Client approve/reject actions writing `ProductSelection#status` + `client_notes`.

---

## 6. House Conventions (enforced — see memory + rails-conventions skill)

- **Tailwind ONLY**, theme palette (`theme-100 #F7F4EF` … `theme-500 #776B63`; plus
  white/black/gray-*). Lone exception: dynamic swatch `background-color: #hex` inline style.
- **`button_to` for every DELETE/PATCH** under Turbo (never a bare `link_to method:`).
- Load **`brooke-maisy`** + **`rails-conventions`** skills before any view work.
- Admin controllers inherit `Admin::BaseController` (auth + `require_admin` + admin layout).
- Pundit policies default-deny base; enforce scoping server-side.
- **NEVER push directly to Heroku — GitHub CI is the gate.** Rubocop runs in CI
  (mind `Layout/SpaceInsideArrayLiteralBrackets`). Brakeman version must match lockfile.
- Sub-project chrome rule does not apply here (this is core app admin, not a sub-project).

---

## 7. Verification per phase

- Phase 0: `bin/rails db:migrate` clean; `bin/rails runner "DesignPresentation; MoodBoard;
  MoodBoardItem; ProductSelection; ColorSwatch"` loads without error; associations work in console.
- Phases 2–4: create/edit/delete each item type via the admin UI; confirm Turbo Stream
  append/replace/remove with no full-page reload; reorder arrows persist `position`.
- Phase 3: upload an image, confirm it lands in R2 (not local disk) and thumbnail renders.
- Phase 5: as a logged-in **client**, hitting a draft presentation's id is denied
  (Pundit) — verify in a request spec, not just by eyeballing.

---

## 8. Open questions for Mason (carry into build session)

1. Multiple presentations per project, or strictly one? Plan assumes `has_many` (allows
   "Round 1 concept" + "Revised concept") but v1 UI can show just the latest.
2. Does Amanda want a per-product `quantity` field, or is that an invoice concern (later)?
3. Color swatches: free-form hex entry only, or eventually a curated brand library
   (Sherwin-Williams / Benjamin Moore picker)? v1 = free-form.
