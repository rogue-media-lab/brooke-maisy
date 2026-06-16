# Brooke & Maisy — Business Software Foundation Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.
> **For Mason:** This is a planning artifact. No code has been written. Review, correct, then approve a phase to begin.

**Goal:** Turn the static Brooke & Maisy marketing site into working interior-design business software — role-based auth (Brooke manages, clients view their projects), a real project/client domain model, an admin management area, and an AI "Room Visualizer" that turns a client photo + prompt into design options with generated images.

**Architecture:** Single Rails 8 app, single Postgres DB, Solid Trifecta already installed. ONE `User` Devise model with a `role` enum (`admin` / `client`) — not two Devise models. Self-registration disabled; Brooke invites clients. AI image work runs async through Solid Queue (already present) calling Google's Gemini 2.5 Flash Image API.

**Tech Stack:** Rails 8.1.3, Ruby 3.4.1, Devise, Pundit (authorization), Active Storage, Solid Queue, TailwindCSS v4 (olive palette), Gemini 2.5 Flash Image API (`gemini-2.5-flash-image`).

**Verified facts (from repo scan 2026-06-16):**
- Devise gem installed, initializer present, `users` table migrated WITH a `role:string` column already.
- `User` model currently has `:registerable` enabled (MUST be removed for invite-only clients).
- No custom Devise views (gem defaults — must be styled to olive palette).
- No `authenticate_user!` enforced anywhere. `role` column unused in code.
- `client_portal`, `project_dashboard`, `trade_network` are static `PagesController` views with empty methods and NO backing models.
- No `Project` / `Client` models exist. No AI gems declared.
- Gemini 2.5 Flash Image API confirmed capable of photo-in → edited-image-out (Google's own "Home Canvas" interior demo). 500 req/day free tier; ~$0.039/image paid.

---

## PHASE 1 — Authentication Foundation

> Gates everything else. Decide the auth model, lock it, style it, enforce it.

### Task 1.1: Lock the User model to invite-only + role enum

**Objective:** Remove public self-registration; formalize admin/client roles.

**Files:**
- Modify: `app/models/user.rb`

**Change `app/models/user.rb` to:**
```ruby
class User < ApplicationRecord
  # registerable intentionally removed — clients are invited by admin, no public sign-up
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum :role, { client: "client", admin: "admin" }, default: "client"

  validates :role, presence: true
end
```

**Verify:** `bin/rails runner "puts User.roles.inspect"` → `{"client"=>"client", "admin"=>"admin"}`

**Commit:** `git commit -m "feat: lock User to invite-only with role enum"`

### Task 1.2: Backfill role default in DB

**Objective:** Ensure existing/new rows have a non-null role.

**Files:**
- Create: `db/migrate/<timestamp>_set_user_role_default.rb`

```ruby
class SetUserRoleDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :role, from: nil, to: "client"
    User.where(role: nil).update_all(role: "client")
  end
end
```

**Run:** `bin/rails db:migrate`
**Verify:** `bin/rails runner "puts User.column_defaults['role']"` → `client`
**Commit:** `git commit -m "feat: set default role=client on users"`

### Task 1.3: Generate and style Devise views (olive palette)

**Objective:** Replace gem defaults with on-brand login / password-reset screens. NO sign-up view (registration disabled).

> Load the `rails-conventions` skill BEFORE touching views. Tailwind only, no inline styles, `button_to` for any DELETE.

**Steps:**
- `bin/rails generate devise:views users` (generates into `app/views/users/`)
- Delete the registrations/new (sign-up) view — invite-only.
- Restyle `sessions/new` and `passwords/*` with the olive palette (olive-100 `#EBEBE5` … olive-500 `#8E8F6B`) and the site's existing nav/footer partials.

**Pitfall:** Do NOT modify `application.html.erb` for Devise — use the sub-project's own layout/partials (Mason's standing rule).

**Verify:** Visit `/users/sign_in` → olive-styled, matches site. `/users/sign_up` → 404/redirect.
**Commit:** `git commit -m "feat: olive-styled Devise login + password reset, sign-up removed"`

### Task 1.4: Add Pundit and enforce authentication

**Objective:** Gate client/admin areas.

**Files:**
- Modify: `Gemfile` (add `gem "pundit"`), run `bundle install`
- Modify: `app/controllers/application_controller.rb`
- Create: `app/policies/application_policy.rb`

**ApplicationController additions:**
```ruby
include Pundit::Authorization
rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

private

def user_not_authorized
  redirect_back fallback_location: root_path, alert: "Not authorized."
end
```

**Verify:** Hitting a soon-to-be-protected action while logged out redirects to sign-in.
**Commit:** `git commit -m "feat: add Pundit authorization scaffolding"`

### Task 1.5: Seed Brooke as admin

**Files:**
- Modify: `db/seeds.rb`

```ruby
admin_email = ENV.fetch("BROOKE_EMAIL", "brooke@brookeandmaisy.com")
User.find_or_create_by!(email: admin_email) do |u|
  u.password = ENV.fetch("BROOKE_PASSWORD") { SecureRandom.base58(16) }
  u.role = "admin"
end
```

**Run:** `bin/rails db:seed`
**Verify:** `bin/rails runner "puts User.find_by(role: 'admin')&.email"`
**Commit:** `git commit -m "feat: seed Brooke admin account"`

---

## PHASE 2 — Domain Models (theater → software)

> Replace the static dashboard mockups with real data scoped per client.

### Task 2.1: Client/Project association decision

**Decision baked in:** `User(role: client)` IS the client. A `Project belongs_to :user`. No separate `Client` table — the design business is small; a client is a user. (If Brooke later wants leads who aren't users, add a `Lead` model then. YAGNI now.)

### Task 2.2: Project model

**Files:**
- Create migration: `projects` (`user_id` fk, `title`, `description:text`, `status:string` default "discovery", `address:string`, timestamps)
- Create: `app/models/project.rb`

```ruby
class Project < ApplicationRecord
  belongs_to :user
  has_many :project_updates, dependent: :destroy
  has_many_attached :photos

  enum :status, {
    discovery: "discovery", design: "design",
    in_progress: "in_progress", complete: "complete"
  }, default: "discovery"

  validates :title, presence: true
end
```
Add `has_many :projects, dependent: :destroy` to `User`.

**Verify:** `bin/rails runner "u=User.first; p u.projects.create!(title: 'Test'); u.projects.count"`
**Commit:** `git commit -m "feat: Project model belongs_to user with photos + status"`

### Task 2.3: ProjectUpdate model (timeline client sees)

**Files:**
- Create migration: `project_updates` (`project_id` fk, `body:text`, `visible_to_client:boolean` default true, timestamps)
- Create: `app/models/project_update.rb`

```ruby
class ProjectUpdate < ApplicationRecord
  belongs_to :project
  scope :client_visible, -> { where(visible_to_client: true) }
  validates :body, presence: true
end
```

**Commit:** `git commit -m "feat: ProjectUpdate timeline model"`

### Task 2.4: Client-facing projects controller + policy

**Objective:** A logged-in client sees ONLY their own projects.

**Files:**
- Create: `app/controllers/client/projects_controller.rb` (namespace `client`)
- Create: `app/policies/project_policy.rb` (scope returns `user.admin? ? Project.all : user.projects`)
- Modify: `config/routes.rb` — `namespace :client { resources :projects, only: [:index, :show] }`, gated by `authenticate_user!`
- Rewire the existing `project_dashboard`/`client_portal` static views into these real views.

**Verify:** Client A cannot load Client B's project (Pundit raises → redirect with alert).
**Commit:** `git commit -m "feat: client project portal scoped by Pundit"`

---

## PHASE 3 — Admin Management Area (Brooke runs the business)

### Task 3.1: Admin namespace + dashboard

**Files:**
- Create: `app/controllers/admin/base_controller.rb` (authorize `admin?` or redirect)
- Create: `app/controllers/admin/dashboard_controller.rb`, `admin/clients_controller.rb`, `admin/projects_controller.rb`
- Modify: `config/routes.rb` — `namespace :admin { root "dashboard#index"; resources :clients; resources :projects }`

> Consider loading `rails-admin-dashboard` skill for the sidebar layout pattern.

**Capabilities:** invite client (create User + send Devise reset/invite email), create/edit projects, post ProjectUpdates, upload photos.
**Commit (per sub-feature):** small commits — `feat: admin dashboard`, `feat: admin client invite`, `feat: admin project CRUD`.

### Task 3.2: Client invitation flow

**Objective:** Brooke creates a client account; system emails a set-password link (no public sign-up).
- Use `User.invite!`-style flow via Devise recoverable: create user with random password, trigger `send_reset_password_instructions`.

**Commit:** `git commit -m "feat: admin-initiated client invitation"`

---

## PHASE 4 — AI Room Visualizer (the differentiator)

> Build LAST, on a verified foundation. Pipeline confirmed: Gemini 2.5 Flash Image edits an uploaded photo from a text prompt. Async via Solid Queue so the web dyno never blocks.

### Task 4.1: Add Gemini client gem + credentials

**Files:**
- Modify: `Gemfile` — add an HTTP client (`gem "faraday"`) or a Gemini wrapper gem; store `GEMINI_API_KEY` in Rails credentials / Heroku config var.
- Verify key works with a one-off curl against `gemini-2.5-flash-image` before writing app code.

**Commit:** `git commit -m "chore: add Gemini API client + credential"`

### Task 4.2: Visualization model

**Files:**
- Create migration: `visualizations` (`project_id` fk, `prompt:text`, `status:string` default "pending", `breakdown:text`, timestamps)
- `has_one_attached :source_photo`, `has_many_attached :result_images`

**Commit:** `git commit -m "feat: Visualization model with source + result attachments"`

### Task 4.3: GenerateVisualizationJob (Solid Queue)

**Objective:** Take source_photo + prompt → call Gemini → attach returned image(s) + text breakdown → flip status to "complete". On failure → status "failed", log, no crash.

**Files:**
- Create: `app/jobs/generate_visualization_job.rb`
- Service object: `app/services/gemini_image_service.rb` (POST source image bytes + prompt, request `responseModalities: ["TEXT","IMAGE"]`, parse inline image data, return {text, [image_blobs]}).

**Verify:** Enqueue with a real shop photo + "replace with light oak hardwood floors" → completes, result image attached.
**Commit:** `git commit -m "feat: async Gemini room visualization job"`

### Task 4.4: Visualizer UI

**Files:**
- Client + admin views: upload photo, type prompt, submit → "generating…" (Turbo Stream / Solid Cable polls status) → show before/after + breakdown.
- Olive palette, Tailwind only.

**Verify:** Full round-trip in browser, multiple options rendered with per-option breakdown (mirrors Mason's Gemini napkin test, productized).
**Commit:** `git commit -m "feat: room visualizer UI with live status"`

---

## Open Decisions for Mason (resolve before Phase 1)

1. **Auth model:** Single `User` + role enum (this plan's assumption) vs. two Devise models like Portfolio. — Recommend single.
2. **Self-registration:** Confirmed OFF / invite-only. Correct?
3. **AI cost posture:** Free tier (500/day) to start, upgrade to paid (~$0.039/image) when volume grows. OK?
4. **Authorization lib:** Pundit (this plan) vs. plain role checks. Pundit recommended for clean per-record scoping.

---

## Execution Note

Each phase is independently shippable. Phase 1 alone gives Brooke a real login. Recommend executing Phase 1 → review → Phase 2, etc., NOT all at once. Paper-design Phase 3 admin + Phase 4 visualizer screens before coding their views (Mason's standing workflow).
