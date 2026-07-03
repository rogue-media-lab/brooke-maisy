# Hermes Read-Only API — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Expose a read-only JSON API so Hermes (in Slack) can query client, project, and message data from the Brooke & Maisy Rails app.

**Architecture:** Namespaced `Api::V1` controllers behind bearer-token authentication. Token stored in Heroku `API_TOKEN` env var. JSON responses use Rails `as_json` with explicit field whitelists — no serializer gem needed. Six endpoints covering clients, projects, messages, and dashboard stats.

**Tech Stack:** Rails 8.1, PostgreSQL, `has_secure_token`-style manual token check (no gem), `as_json` serialization.

**Assumptions decided with Mason:**
- Auth: static API token (bearer header)
- Access: read-only (no write endpoints in v1)
- Hermes stores token + base URL, calls API, formats responses for Slack

---

### Task 1: Generate API token and set Heroku env var

**Objective:** Create a cryptographically random token and store it as a Heroku config var.

**Step 1: Generate the token**

```bash
bin/rails runner "puts SecureRandom.hex(32)"
```

Copy the output (64 hex chars). Example: `a1b2c3d4e5f6...`.

**Step 2: Set on Heroku**

```bash
heroku config:set API_TOKEN=<the_token> -a brooke-maisy
```

**Step 3: Verify**

```bash
heroku config:get API_TOKEN -a brooke-maisy
```

Should echo the token back.

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: generate API_TOKEN for Hermes API"
```

> No code changes yet — just the env var set.

---

### Task 2: Create Api::V1::BaseController with token auth

**Objective:** Build the base controller that all API endpoints inherit from. It reads `Authorization: Bearer <token>` and compares against `ENV['API_TOKEN']`.

**Files:**
- Create: `app/controllers/api/v1/base_controller.rb`
- Create: `app/controllers/api/v1/` directory structure

**Step 1: Create directory structure**

```bash
mkdir -p app/controllers/api/v1
```

**Step 2: Write base controller**

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      # Skip CSRF — API uses bearer tokens, not cookies.
      skip_before_action :verify_authenticity_token

      before_action :authenticate!

      private

      def authenticate!
        head :unauthorized and return if api_token.blank?

        head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(
          api_token, ENV.fetch("API_TOKEN", "")
        )
      end

      def api_token
        pattern = /^Bearer /
        header  = request.authorization
        return unless header&.match(pattern)

        header.gsub(pattern, "")
      end
    end
  end
end
```

**Key details:**
- `secure_compare` prevents timing attacks on token comparison.
- Returns `401 Unauthorized` with empty body when token is missing or wrong.
- Skips CSRF — no session cookies in API requests.

**Step 3: Verify the file exists and is syntactically valid**

```bash
ruby -c app/controllers/api/v1/base_controller.rb
```

**Step 4: Commit**

```bash
git add app/controllers/api/v1/
git commit -m "feat: add Api::V1::BaseController with bearer token auth"
```

---

### Task 3: Add API routes

**Objective:** Wire the `api/v1` namespace into `config/routes.rb`.

**File:** Modify `config/routes.rb`

**Step 1: Add the namespace block**

Insert BEFORE the final `end` in routes.rb (before line 68):

```ruby
  # Read-only API for Hermes Slack integration
  namespace :api do
    namespace :v1 do
      resources :clients, only: [ :index, :show ]
      resources :projects, only: [ :index, :show ]
      resources :messages, only: [ :index, :show ]
      get "stats", to: "stats#show"
    end
  end
```

**Full routes.rb after the change:**

```ruby
Rails.application.routes.draw do
  # Invitation-only: registration disabled. Clients are created by an admin.
  devise_for :users, skip: [ :registrations ]
  # Error pages
  match "/404", to: "errors#not_found",             via: :all
  match "/422", to: "errors#unprocessable_entity",  via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # Reveal health status on /up
  get "up" => "rails/health#show", as: :rails_health_check

  # Page routes
  get "/", to: "pages#home", as: :root
  get "about", to: "pages#about"
  get "services", to: "pages#services"
  get "portfolio", to: "pages#portfolio"
  get "contact", to: "pages#contact"
  resources :messages, only: [ :create ]
  resources :questionnaire_submissions, only: [ :new, :create ], path: "client-questionnaire"
  get "trade-network", to: "pages#trade_network"

  # Authenticated client portal
  namespace :client do
    resources :projects, only: [ :index, :show ]
  end

  # Admin area
  namespace :admin do
    root "dashboard#index"
    resources :clients do
      member do
        post :resend_invite
      end
    end
    resources :projects do
      resources :project_updates, only: [ :create, :destroy ]
      resources :design_presentations do
        resource :publication, only: [ :create, :destroy ]
        resources :mood_boards do
          member do
            patch :move
          end
          resources :mood_board_items do
            member do
              patch :move
            end
          end
        end
        resources :product_selections do
          member do
            patch :move
          end
        end
        resources :color_swatches do
          member do
            patch :move
          end
        end
      end
    end
    resources :messages, only: [ :index, :show, :destroy ]
    resources :questionnaire_submissions, only: [ :index, :show, :destroy ]
  end

  # Read-only API for Hermes Slack integration
  namespace :api do
    namespace :v1 do
      resources :clients, only: [ :index, :show ]
      resources :projects, only: [ :index, :show ]
      resources :messages, only: [ :index, :show ]
      get "stats", to: "stats#show"
    end
  end

  # Public "client-portal" link routes into the authenticated portal.
  get "client-portal", to: redirect("/client/projects")
end
```

**Step 2: Verify routes**

```bash
bin/rails routes | grep 'api/v1'
```

Expected output (trimmed):

```
api_v1_clients  GET  /api/v1/clients      api/v1/clients#index
api_v1_client   GET  /api/v1/clients/:id   api/v1/clients#show
api_v1_projects GET  /api/v1/projects      api/v1/projects#index
api_v1_project  GET  /api/v1/projects/:id   api/v1/projects#show
api_v1_messages GET  /api/v1/messages      api/v1/messages#index
api_v1_message  GET  /api/v1/messages/:id   api/v1/messages#show
api_v1_stats    GET  /api/v1/stats          api/v1/stats#show
```

**Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "feat: add api/v1 routes for Hermes read-only API"
```

---

### Task 4: Build Api::V1::ClientsController

**Objective:** Expose client list (searchable) and individual client detail with their projects.

**Files:**
- Create: `app/controllers/api/v1/clients_controller.rb`

**Step 1: Write the controller**

```ruby
# app/controllers/api/v1/clients_controller.rb
module Api
  module V1
    class ClientsController < BaseController
      def index
        clients = User.clients
        clients = search_clients(clients) if params[:q].present?
        render json: clients.map { |c| client_json(c) }
      end

      def show
        client = User.clients.find(params[:id])
        render json: client_json(client).merge(
          projects: client.projects.recent.map { |p| project_summary_json(p) }
        )
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Client not found" }, status: :not_found
      end

      private

      def search_clients(scope)
        q = "%#{params[:q]}%"
        scope.where("name ILIKE ? OR email ILIKE ?", q, q)
      end

      def client_json(client)
        {
          id: client.id,
          name: client.name,
          email: client.email,
          display_name: client.display_name,
          project_count: client.projects.count,
          created_at: client.created_at.iso8601
        }
      end

      def project_summary_json(project)
        {
          id: project.id,
          title: project.title,
          status: project.status,
          address: project.address,
          created_at: project.created_at.iso8601,
          updated_at: project.updated_at.iso8601
        }
      end
    end
  end
end
```

**Key details:**
- `index` supports `?q=Jane` search on name and email (ILIKE for case-insensitive).
- `show` includes the client's projects as a nested array.
- `clients` scope filters to `role: "client"` only — never exposes admin users.
- Never exposes `encrypted_password`, `reset_password_token`, or `remember_created_at`.

**Step 2: Verify syntax**

```bash
ruby -c app/controllers/api/v1/clients_controller.rb
```

**Step 3: Commit**

```bash
git add app/controllers/api/v1/clients_controller.rb
git commit -m "feat: add Api::V1::ClientsController with search"
```

---

### Task 5: Build Api::V1::ProjectsController

**Objective:** List and show projects with filtering by status and client, plus nested updates and photo URLs.

**Files:**
- Create: `app/controllers/api/v1/projects_controller.rb`

**Step 1: Write the controller**

```ruby
# app/controllers/api/v1/projects_controller.rb
module Api
  module V1
    class ProjectsController < BaseController
      def index
        projects = Project.recent.includes(:user).with_attached_photos
        projects = filter_by_status(projects)  if params[:status].present?
        projects = filter_by_client(projects)  if params[:client_id].present?
        projects = search_title(projects)      if params[:q].present?

        render json: projects.map { |p| project_detail_json(p) }
      end

      def show
        project = Project.includes(:user, :project_updates)
                         .with_attached_photos
                         .find(params[:id])
        render json: project_detail_json(project).merge(
          client: client_ref_json(project.user),
          updates: project.project_updates.recent.map { |u| update_json(u) }
        )
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found" }, status: :not_found
      end

      private

      def filter_by_status(scope)
        scope.where(status: params[:status])
      end

      def filter_by_client(scope)
        scope.where(user_id: params[:client_id])
      end

      def search_title(scope)
        scope.where("title ILIKE ?", "%#{params[:q]}%")
      end

      def project_detail_json(project)
        {
          id: project.id,
          title: project.title,
          status: project.status,
          description: project.description,
          address: project.address,
          client: client_ref_json(project.user),
          photo_urls: project.photos.map { |p| url_for(p) },
          created_at: project.created_at.iso8601,
          updated_at: project.updated_at.iso8601
        }
      end

      def client_ref_json(user)
        {
          id: user.id,
          name: user.name,
          display_name: user.display_name,
          email: user.email
        }
      end

      def update_json(update)
        {
          id: update.id,
          body: update.body,
          visible_to_client: update.visible_to_client,
          created_at: update.created_at.iso8601
        }
      end

      # url_for(attachment) requires including the URL helpers in the controller context.
      # Active Storage's url_for is available via Rails.application.routes.url_helpers.
      def url_for(attachment)
        Rails.application.routes.url_helpers.rails_blob_url(
          attachment, host: ENV.fetch("API_HOST_URL", "https://brooke-maisy-b5080025ac4e.herokuapp.com")
        )
      end
    end
  end
end
```

**Key details:**
- `index` supports `?status=discovery`, `?client_id=5`, `?q=kitchen` — all combinable.
- `show` nests `client`, `updates`, and `photo_urls` (full URLs to Active Storage blobs).
- `url_for` helper generates full Heroku URLs for photos so Hermes can display them.
- `with_attached_photos` avoids N+1 queries.
- `API_HOST_URL` env var allows overriding the host (e.g., `brookenmaisy.com`), falling back to the Heroku default.

**Step 2: Verify syntax**

```bash
ruby -c app/controllers/api/v1/projects_controller.rb
```

**Step 3: Commit**

```bash
git add app/controllers/api/v1/projects_controller.rb
git commit -m "feat: add Api::V1::ProjectsController with filters and photo URLs"
```

---

### Task 6: Build Api::V1::MessagesController

**Objective:** List and show contact form messages, with an unread filter.

**Files:**
- Create: `app/controllers/api/v1/messages_controller.rb`

**Step 1: Write the controller**

```ruby
# app/controllers/api/v1/messages_controller.rb
module Api
  module V1
    class MessagesController < BaseController
      def index
        messages = Message.recent
        messages = messages.unread if params[:unread] == "true"

        render json: messages.map { |m| message_json(m) }
      end

      def show
        message = Message.find(params[:id])
        render json: message_json(message)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Message not found" }, status: :not_found
      end

      private

      def message_json(message)
        {
          id: message.id,
          name: message.name,
          email: message.email,
          phone: message.phone,
          service: message.service,
          body: message.body,
          read: message.read,
          created_at: message.created_at.iso8601
        }
      end
    end
  end
end
```

**Key details:**
- `?unread=true` filters to only unread messages.
- `index` returns all messages by default (newest first).
- `show` does NOT auto-mark as read (unlike the admin web UI) — keeps the API side-effect-free.

**Step 2: Verify syntax**

```bash
ruby -c app/controllers/api/v1/messages_controller.rb
```

**Step 3: Commit**

```bash
git add app/controllers/api/v1/messages_controller.rb
git commit -m "feat: add Api::V1::MessagesController with unread filter"
```

---

### Task 7: Build Api::V1::StatsController

**Objective:** Single endpoint returning dashboard summary — project counts by status, total clients, unread messages.

**Files:**
- Create: `app/controllers/api/v1/stats_controller.rb`

**Step 1: Write the controller**

```ruby
# app/controllers/api/v1/stats_controller.rb
module Api
  module V1
    class StatsController < BaseController
      def show
        render json: {
          projects: {
            total: Project.count,
            discovery: Project.where(status: "discovery").count,
            design: Project.where(status: "design").count,
            in_progress: Project.where(status: "in_progress").count,
            complete: Project.where(status: "complete").count
          },
          clients: {
            total: User.clients.count
          },
          messages: {
            total: Message.count,
            unread: Message.unread.count
          },
          generated_at: Time.current.iso8601
        }
      end
    end
  end
end
```

**Step 2: Verify syntax**

```bash
ruby -c app/controllers/api/v1/stats_controller.rb
```

**Step 3: Commit**

```bash
git add app/controllers/api/v1/stats_controller.rb
git commit -m "feat: add Api::V1::StatsController with dashboard summary"
```

---

### Task 8: Test locally with curl

**Objective:** Verify all six endpoints return correct JSON with valid token and 401 without.

**Prerequisite:** Set `API_TOKEN` in your local environment:

```bash
export API_TOKEN=$(heroku config:get API_TOKEN -a brooke-maisy)
export API_HOST_URL="http://localhost:3000"
```

**Step 1: Start the dev server**

```bash
unset DATABASE_URL  # avoid the empty-DATABASE_URL pitfall
cd /home/masonroberts/Rogue-Media-Lab/Studio-Projects/RML-Brooke-Maisy/brooke-maisy
bin/dev &
```

Wait for the server to boot (watch for `Listening on http://127.0.0.1:3000`).

**Step 2: Test auth rejection (no token)**

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/clients
# Expected: 401
```

**Step 3: Test auth rejection (wrong token)**

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer wrong-token" \
  http://localhost:3000/api/v1/clients
# Expected: 401
```

**Step 4: Test clients index**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:3000/api/v1/clients | python3 -m json.tool
# Expected: JSON array of client objects
```

**Step 5: Test clients search**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "http://localhost:3000/api/v1/clients?q=Amanda" | python3 -m json.tool
```

**Step 6: Test client show (replace `1` with a real client ID)**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:3000/api/v1/clients/1 | python3 -m json.tool
# Expected: client JSON with nested "projects" array
```

**Step 7: Test projects index**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:3000/api/v1/projects | python3 -m json.tool
```

**Step 8: Test projects filter by status**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "http://localhost:3000/api/v1/projects?status=discovery" | python3 -m json.tool
```

**Step 9: Test projects filter by client**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "http://localhost:3000/api/v1/projects?client_id=1" | python3 -m json.tool
```

**Step 10: Test messages**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:3000/api/v1/messages | python3 -m json.tool
```

**Step 11: Test messages unread**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  "http://localhost:3000/api/v1/messages?unread=true" | python3 -m json.tool
```

**Step 12: Test stats**

```bash
curl -s -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:3000/api/v1/stats | python3 -m json.tool
```

**All should return valid JSON, never 500s.** If any fail, debug the controller before proceeding.

**Step 13: Stop the server**

```bash
kill %1
```

**Step 14: Commit (if any fixes were needed)**

```bash
git add -A
git commit -m "test: verify all API endpoints return correct JSON locally"
```

---

### Task 9: Push to GitHub and deploy to Heroku

**Objective:** Get the API live on production.

**Step 1: Push to GitHub**

```bash
git push origin main
```

**Step 2: Wait for CI to pass**

Watch the GitHub Actions run at: `https://github.com/rogue-media-lab/brooke-maisy/actions`

**Step 3: Verify CI passed, then deploy**

Heroku auto-deploys on push to `main` if connected. If not:

```bash
# Heroku deploys automatically via GitHub integration — just verify it deployed:
heroku releases -a brooke-maisy --num 1
```

**Step 4: Test against production**

```bash
PROD_TOKEN=$(heroku config:get API_TOKEN -a brooke-maisy)

# Test stats (lightweight, no DB load)
curl -s -H "Authorization: Bearer $PROD_TOKEN" \
  https://brooke-maisy-b5080025ac4e.herokuapp.com/api/v1/stats | python3 -m json.tool

# Test clients
curl -s -H "Authorization: Bearer $PROD_TOKEN" \
  https://brooke-maisy-b5080025ac4e.herokuapp.com/api/v1/clients | python3 -m json.tool
```

**Step 5: Commit**

```bash
git add -A
git commit -m "deploy: API endpoints live on Heroku"
```

---

### Task 10: Set custom domain host URL

**Objective:** Ensure photo URLs use `brookenmaisy.com` instead of the Heroku default.

**Step 1: Set the env var on Heroku**

```bash
heroku config:set API_HOST_URL="https://brookenmaisy.com" -a brooke-maisy
```

**Step 2: Verify photo URLs use the custom domain**

```bash
PROD_TOKEN=$(heroku config:get API_TOKEN -a brooke-maisy)
curl -s -H "Authorization: Bearer $PROD_TOKEN" \
  https://brooke-maisy-b5080025ac4e.herokuapp.com/api/v1/projects/1 | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('photo_urls',[]))"
```

All URLs should start with `https://brookenmaisy.com/`.

**Step 3: Commit**

No code changes — just document the env var.

---

## API Reference (post-implementation)

### Authentication
All requests require: `Authorization: Bearer <API_TOKEN>`

### Endpoints

| Method | Path | Query Params | Description |
|--------|------|-------------|-------------|
| GET | `/api/v1/clients` | `?q=name` | List/search clients |
| GET | `/api/v1/clients/:id` | — | Client detail + projects |
| GET | `/api/v1/projects` | `?status=X&client_id=N&q=title` | List/filter projects |
| GET | `/api/v1/projects/:id` | — | Project detail + updates + photos |
| GET | `/api/v1/messages` | `?unread=true` | List messages |
| GET | `/api/v1/messages/:id` | — | Single message detail |
| GET | `/api/v1/stats` | — | Dashboard summary |

### Response codes
- `200` — success
- `401` — missing or invalid token
- `404` — resource not found

---

## Hermes Integration (next step, after API is live)

1. Store the API token + base URL in Hermes config or memory.
2. Create a skill that teaches Hermes how to call the API (endpoints, query params, response shapes).
3. Hermes formats API responses as Slack-friendly messages (bullet lists, status emoji, etc.).

Not covered in this implementation plan — separate follow-up work.

---

## Pitfalls

### Empty DATABASE_URL kills local testing
Always `unset DATABASE_URL` before running `bin/dev` or any Rails command locally. The skill docs cover this — it's a shell state issue, not a code bug.

### `url_for` in controllers requires explicit host
Active Storage's `url_for` in a controller context doesn't know the request host (API requests are headless). Must pass `host:` explicitly — we use `ENV['API_HOST_URL']` with a Heroku fallback.

### Devise filters don't interfere
The `BaseController` inherits from `ApplicationController` but skips CSRF. Devise's `authenticate_user!` is NOT called — API auth is purely token-based.

### Never push directly to Heroku
GitHub CI is the gate. Push to `origin main`, let CI pass, Heroku auto-deploys.

### Commit exactly what changed
Each task commits only the files it created or modified. Use `git status` before each commit to verify no unrelated files are staged.