# Client Decoupling & Quote Workflow Refactor

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Decouple the client person from the Devise login, allow standalone quotes without a project, fix the PO client linkage, regroup the admin sidebar, add a security-gated margin view, and clean up dead code.

**Architecture:** Introduce a `Client` model that anchors quotes, projects, and POs. `User` becomes an optional login credential `belongs_to :client`. Quotes become a top-level admin resource (unnested from projects). The admin quote view defaults to retail-only presentation; margins are hidden behind a session-pinned Stimulus unlock. Purchase orders always have a client, optionally a quote and project.

**Tech Stack:** Rails 8.1, PostgreSQL, Tailwind v4, Stimulus, Pundit, Devise

---

## Phase 1: Introduce Client Model (Decouple Person from Login)

### Task 1: Create Client model and migration

**Objective:** Create the `clients` table that holds client identity separate from login.

**Files:**
- Create: `db/migrate/{timestamp}_create_clients.rb`
- Create: `app/models/client.rb`

**Step 1: Generate migration**

```bash
bin/rails generate model Client name:string address:string phone:string email:string notes:text
```

**Step 2: Edit migration** — add `null: false` to `name`, add indexes:

```ruby
class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :address
      t.string :phone
      t.string :email
      t.text :notes

      t.timestamps
    end

    add_index :clients, :email
    add_index :clients, :name
  end
end
```

**Step 3: Run migration**

```bash
unset DATABASE_URL && bin/rails db:migrate
```

**Step 4: Write Client model**

```ruby
# app/models/client.rb
class Client < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :purchase_orders, dependent: :nullify
  has_one :user, dependent: :restrict_with_error

  validates :name, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :alphabetical, -> { order(:name) }

  def display_name
    name
  end

  def first_name
    name.split.first
  end

  def portal_enabled?
    user.present?
  end
end
```

**Step 5: Commit**

```bash
git add app/models/client.rb db/migrate/*_create_clients.rb db/schema.rb
git commit -m "feat: add Client model — decouples person from Devise login"
```

---

### Task 2: Link User to Client (optional belongs_to)

**Objective:** User (Devise login) now optionally belongs to a Client. The login is a portal key, not the identity.

**Files:**
- Create: `db/migrate/{timestamp}_add_client_reference_to_users.rb`
- Modify: `app/models/user.rb`
- Modify: `app/models/client.rb`

**Step 1: Generate migration**

```bash
bin/rails generate migration AddClientReferenceToUsers client:references
```

**Step 2: Edit migration** — make the FK nullable (a user may exist before being linked):

```ruby
class AddClientReferenceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :client, foreign_key: true, null: true
    add_index :users, :client_id
  end
end
```

**Step 3: Run migration**

```bash
unset DATABASE_URL && bin/rails db:migrate
```

**Step 4: Update User model**

```ruby
# app/models/user.rb — replace existing associations
class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum :role, { client: "client", tech: "tech", admin: "admin" }, default: "client"

  belongs_to :client, optional: true

  validates :role, presence: true

  scope :clients, -> { where(role: "client").order(:name) }
  scope :techs, -> { where(role: "tech").order(:name) }

  def display_name
    name.presence || client&.name || email.split("@").first.titleize
  end

  def first_name
    display_name.split.first
  end
end
```

Remove `has_many :projects` and `has_many :quotes` from User — these move to Client.

**Step 5: Commit**

```bash
git add app/models/user.rb app/models/client.rb db/migrate/*_add_client_reference_to_users.rb db/schema.rb
git commit -m "feat: User belongs_to Client (optional) — login decoupled from identity"
```

---

### Task 3: Migrate projects.user_id → projects.client_id

**Objective:** Projects anchor to Client, not User. The client_id column is added; existing user_id data is migrated to client_id.

**Files:**
- Create: `db/migrate/{timestamp}_add_client_reference_to_projects.rb`
- Modify: `app/models/project.rb`
- Modify: `app/models/client.rb`

**Step 1: Generate migration**

```bash
bin/rails generate migration AddClientReferenceToProjects client:references
```

**Step 2: Edit migration** — add column nullable first, then backfill, then enforce not null:

```ruby
class AddClientReferenceToProjects < ActiveRecord::Migration[8.1]
  def up
    add_reference :projects, :client, foreign_key: true, null: true
    add_index :projects, :client_id

    # Backfill: for each project, create a Client from the linked User
    Project.find_each do |project|
      next unless project.user_id.present?
      user = User.find_by(id: project.user_id)
      next unless user

      client = Client.find_or_create_by!(
        name: user.name || user.email.split("@").first.titleize
      ) do |c|
        c.email = user.email
      end
      project.update_column(:client_id, client.id)

      # Link the user to the client (if not already linked)
      user.update_column(:client_id, client.id) unless user.client_id.present?
    end

    # Enforce not null now that data is backfilled
    change_column_null :projects, :client_id, false
  end

  def down
    remove_reference :projects, :client
  end
end
```

**Step 3: Run migration**

```bash
unset DATABASE_URL && bin/rails db:migrate
```

**Step 4: Update Project model**

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :client
  has_many :project_updates, dependent: :destroy
  has_many :design_presentations, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :purchase_orders, dependent: :nullify
  has_many_attached :photos

  enum :status, {
    discovery: "discovery",
    design: "design",
    in_progress: "in_progress",
    complete: "complete"
  }, default: "discovery"

  validates :title, presence: true
  validates :status, presence: true
  validates :client, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
```

Note: `belongs_to :client` is required. The old `belongs_to :user` is removed. `user_id` column stays in the DB for now (removed in a later cleanup migration).

**Step 5: Commit**

```bash
git add app/models/project.rb app/models/client.rb db/migrate/*_add_client_reference_to_projects.rb db/schema.rb
git commit -m "feat: Project belongs_to Client — backfilled from existing User records"
```

---

### Task 4: Migrate quotes.client_id from User to Client

**Objective:** The `quotes.client_id` column currently references `users.id`. It needs to reference `clients.id`. This is a data migration, not just a schema change.

**Files:**
- Create: `db/migrate/{timestamp}_migrate_quote_client_to_client_model.rb`
- Modify: `app/models/quote.rb`

**Step 1: Generate migration**

```bash
bin/rails generate migration MigrateQuoteClientToClientModel
```

**Step 2: Write migration** — remap existing `client_id` values from User IDs to Client IDs:

```ruby
class MigrateQuoteClientToClientModel < ActiveRecord::Migration[8.1]
  def up
    # For each quote, the existing client_id points to a User.
    # Find or create the corresponding Client, then update the FK.
    Quote.find_each do |quote|
      next unless quote.client_id.present?
      user = User.find_by(id: quote.client_id)
      next unless user

      # Find the client that was backfilled from this user
      client = Client.find_by(email: user.email) ||
               Client.find_or_create_by!(name: user.name || user.email.split("@").first.titleize) do |c|
                 c.email = user.email
               end

      quote.update_column(:client_id, client.id)
    end

    # The FK constraint already exists pointing to users.
    # We need to drop it and re-add pointing to clients.
    remove_foreign_key :quotes, :users, column: :client_id rescue nil
    add_foreign_key :quotes, :clients, column: :client_id
  end

  def down
    remove_foreign_key :quotes, :clients, column: :client_id
    add_foreign_key :quotes, :users, column: :client_id
  end
end
```

**Step 3: Run migration**

```bash
unset DATABASE_URL && bin/rails db:migrate
```

**Step 4: Update Quote model**

```ruby
# app/models/quote.rb — change the client association
class Quote < ApplicationRecord
  belongs_to :client             # NOW: Client model, not User
  belongs_to :project, optional: true  # Phase 2 will make this optional
  belongs_to :promo_code, optional: true
  has_many :quote_line_items, dependent: :destroy
  has_many :quote_revisions, dependent: :destroy
  has_many :purchase_orders, dependent: :nullify

  # ... rest stays the same
end
```

Remove `class_name: "User"` from the `belongs_to :client` declaration.

**Step 5: Commit**

```bash
git add app/models/quote.rb db/migrate/*_migrate_quote_client.rb db/schema.rb
git commit -m "feat: Quote.client_id now references Client model (data migrated)"
```

---

### Task 5: Update Admin::ClientsController to use Client model

**Objective:** The admin clients controller currently manages `User` records with role "client". It should now manage `Client` records. User creation (invite flow) becomes a separate action.

**Files:**
- Modify: `app/controllers/admin/clients_controller.rb`
- Modify: `app/views/admin/clients/index.html.erb`
- Modify: `app/views/admin/clients/show.html.erb`
- Modify: `app/views/admin/clients/new.html.erb`
- Modify: `app/views/admin/clients/edit.html.erb`
- Modify: `app/views/admin/clients/_form.html.erb`
- Modify: `app/views/admin/clients/_quick_form.html.erb`
- Modify: `app/views/admin/clients/_client_dropdown.html.erb`

**Step 1: Rewrite Admin::ClientsController**

```ruby
# app/controllers/admin/clients_controller.rb
class Admin::ClientsController < Admin::BaseController
  before_action :set_client, only: [ :show, :edit, :update, :destroy, :resend_invite, :invite ]

  def index
    @clients = Client.alphabetical
  end

  def show
    @projects = @client.projects.recent
    @quotes = @client.quotes.live.recent.limit(5)
  end

  def new
    @client = Client.new
    render :quick, layout: "admin_minimal" if params[:quick]
  end

  def selector
    @clients = Client.alphabetical
    @selected_id = params[:selected_id]
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      if params[:return_to].present?
        separator = params[:return_to].include?("?") ? "&" : "?"
        redirect_to "#{params[:return_to]}#{separator}new_client_id=#{@client.id}",
                    notice: "#{@client.display_name} added and selected."
      else
        redirect_to admin_client_path(@client), notice: "Client added."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to admin_client_path(@client), notice: "Client updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path, notice: "Client removed."
  end

  # Invite flow: create a User linked to this Client, send set-password email
  def invite
    if @client.user.present?
      @client.user.send_reset_password_instructions
      redirect_to admin_client_path(@client), notice: "Invitation email re-sent."
    else
      user = User.new(
        client: @client,
        name: @client.name,
        email: @client.email,
        role: "client",
        password: SecureRandom.base58(24)
      )
      if user.save
        user.send_reset_password_instructions
        redirect_to admin_client_path(@client), notice: "Portal access enabled. A set-password email has been sent."
      else
        redirect_to admin_client_path(@client), alert: "Could not invite: #{user.errors.full_messages.to_sentence}. An email is required."
      end
    end
  end

  def resend_invite
    invite
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone, :address, :notes)
  end
end
```

**Step 2: Update routes** — add `invite` member route:

```ruby
# config/routes.rb — inside admin namespace, replace existing :clients resource
resources :clients do
  member do
    post :invite
    post :resend_invite
  end
  collection do
    get :selector
  end
end
```

**Step 3: Update _quick_form** — remove email required, add address:

```erb
<%# app/views/admin/clients/_quick_form.html.erb %>
<%= form_with model: client, url: admin_clients_path, class: "space-y-3 bg-theme-50 border border-theme-200 rounded-lg p-4" do |f| %>
  <p class="text-xs font-semibold text-theme-500 uppercase tracking-wide">New Client</p>
  <%= hidden_field_tag :return_to, local_assigns[:return_to] %>

  <div>
    <%= f.label :name, class: "block text-xs font-medium text-gray-700 mb-1" %>
    <%= f.text_field :name, class: "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500 text-sm", placeholder: "Full name", required: true %>
  </div>

  <div>
    <%= f.label :address, class: "block text-xs font-medium text-gray-700 mb-1" %>
    <%= f.text_field :address, class: "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500 text-sm", placeholder: "Street, City, State ZIP" %>
  </div>

  <div>
    <%= f.label :phone, class: "block text-xs font-medium text-gray-700 mb-1" %>
    <%= f.text_field :phone, class: "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500 text-sm", placeholder: "(803) 555-1234" %>
  </div>

  <div>
    <%= f.label :email, class: "block text-xs font-medium text-gray-700 mb-1" %>
    <%= f.email_field :email, class: "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500 text-sm", placeholder: "Optional — needed for portal access" %>
    <p class="text-xs text-gray-400 mt-1">Leave blank if you don't have it yet. Add later to enable portal access.</p>
  </div>

  <div class="flex gap-2">
    <%= f.submit "Create & select", class: "bg-theme-500 hover:bg-theme-400 text-white text-xs font-semibold px-3 py-2 rounded-lg cursor-pointer transition-colors" %>
    <%= link_to "Cancel", local_assigns[:return_to] || admin_clients_path, class: "text-xs text-gray-500 hover:text-gray-700 py-2" %>
  </div>
<% end %>
```

**Step 4: Update _client_dropdown** — use Client collection:

```erb
<%# app/views/admin/clients/_client_dropdown.html.erb %>
<div class="flex items-end gap-2">
  <div class="flex-1">
    <%= form.label field_name, "Client", class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= form.collection_select field_name, clients, :id, :display_name,
          { prompt: "Select client...", selected: local_assigns[:selected_id]&.to_i },
          class: "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500" %>
  </div>
  <%= link_to "New client", new_admin_client_path(quick: 1, return_to: local_assigns[:return_to]),
        class: "text-xs text-theme-500 hover:text-theme-400 font-medium whitespace-nowrap pb-1" %>
</div>
```

**Step 5: Update client show view** — add "Invite to portal" button:

```erb
<%# In admin/clients/show.html.erb — add after client info section %>
<div class="bg-white rounded-xl border border-theme-100 p-6 mb-6">
  <h2 class="font-serif text-lg font-semibold text-theme-500 mb-3">Portal Access</h2>
  <% if @client.portal_enabled? %>
    <p class="text-sm text-green-600 mb-2">Portal enabled — <%= @client.user.email %></p>
    <%= button_to "Resend invite", resend_invite_admin_client_path(@client), method: :post,
          class: "bg-theme-100 hover:bg-theme-200 text-theme-500 text-sm font-medium px-4 py-2 rounded-lg" %>
  <% else %>
    <p class="text-sm text-gray-400 mb-2">No portal access. <% if @client.email.blank? %>Add an email first.<% else %></p>
    <%= button_to "Enable portal access", invite_admin_client_path(@client), method: :post,
          class: "bg-theme-500 hover:bg-theme-400 text-white text-sm font-semibold px-4 py-2 rounded-lg" %>
    <% end %>
  <% end %>
</div>
```

**Step 6: Update dashboard controller** — use Client instead of User:

```ruby
# app/controllers/admin/dashboard_controller.rb
@client_count = Client.count
```

**Step 7: Update admin projects controller** — `client_id` instead of `user_id`:

```ruby
# app/controllers/admin/projects_controller.rb
def index
  @projects = Project.includes(:client).recent
  @projects = @projects.where(status: params[:status]) if params[:status].present?
  @projects = @projects.where(client_id: params[:client_id]) if params[:client_id].present?
end

def show
  # ... existing ...
  @quotes = @project.quotes.live.includes(:client).recent.limit(5)
end

def new
  @project = Project.new
  @project.client_id = params[:client_id] if params[:client_id].present?
  @clients = Client.alphabetical
end

def project_params
  params.require(:project).permit(:client_id, :title, :description, :status, :address, photos: [])
end
```

**Step 8: Update project views** — replace `user` references with `client`:
- `admin/projects/show.html.erb:15` — `@project.user.display_name` → `@project.client.display_name`
- `admin/projects/show.html.erb:15` — `admin_client_path(@project.user)` → `admin_client_path(@project.client)`
- `admin/projects/_form.html.erb` — `:user_id` → `:client_id`, use `Client.alphabetical`
- `admin/dashboard/index.html.erb:46` — `project.user.display_name` → `project.client.display_name`

**Step 9: Run rubocop + commit**

```bash
bundle exec rubocop -a
git add app/controllers/ app/models/ app/views/ config/routes.rb db/schema.rb
git commit -m "feat: Admin::ClientsController now manages Client model — invite flow is separate action"
```

---

## Phase 2: Decouple Quote from Project (Standalone Quotes)

### Task 6: Make Quote.project optional and unnest routes

**Objective:** Quotes become a top-level admin resource. A quote belongs to a Client (required) and optionally to a Project.

**Files:**
- Create: `db/migrate/{timestamp}_make_quote_project_optional.rb`
- Modify: `app/models/quote.rb`
- Modify: `config/routes.rb`
- Modify: `app/controllers/admin/quotes_controller.rb`
- Modify: all views referencing `admin_project_quote_path` and `admin_project_quotes_path`

**Step 1: Migration — make project_id nullable**

```ruby
class MakeQuoteProjectOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :quotes, :project_id, true
  end
end
```

**Step 2: Run migration**

```bash
unset DATABASE_URL && bin/rails db:migrate
```

**Step 3: Update Quote model**

```ruby
# app/models/quote.rb
belongs_to :project, optional: true   # was: belongs_to :project (required)
```

**Step 4: Unnest routes** — quotes become top-level in admin:

```ruby
# config/routes.rb — inside namespace :admin, REPLACE the nested quotes block:
# REMOVE from inside resources :projects:
#   resources :quotes do ... end

# ADD as top-level admin resource:
resources :quotes do
  member do
    post :send_quote
    get :preview
    post :save_as_template
    post :convert_to_project
  end
  resources :quote_line_items, only: [ :new, :create, :edit, :update, :destroy ]
end
```

Keep `resources :projects` with `resources :project_updates`, `resources :rooms`, `resources :design_presentations` — but remove the `resources :quotes` block from inside it.

**Step 5: Rewrite Admin::QuotesController** — remove project nesting:

```ruby
# app/controllers/admin/quotes_controller.rb
class Admin::QuotesController < Admin::BaseController
  before_action :set_quote, only: [ :show, :edit, :update, :destroy, :send_quote, :preview, :save_as_template, :convert_to_project ]

  def index
    @quotes = Quote.live.includes(:client, :project).recent
    @quotes = @quotes.where(project_id: params[:project_id]) if params[:project_id].present?
    @quotes = @quotes.where(client_id: params[:client_id]) if params[:client_id].present?
  end

  def templates
    @templates = Quote.templates.includes(:client, :project).recent
  end

  def load
    template = Quote.templates.find(params[:template_id])
    new_quote = Quote.new(
      client_id: params[:client_id] || template.client_id,
      project_id: params[:project_id],
      notes: template.notes,
      tax_rate: template.tax_rate,
      deposit_percentage: template.deposit_percentage,
      valid_until: 30.days.from_now.to_date,
      is_template: false,
      version_number: 1
    )
    if new_quote.save
      template.quote_line_items.ordered.each do |item|
        new_quote.quote_line_items.create!(...same as before...)
      end
      redirect_to admin_quote_path(new_quote), notice: "Quote created from template."
    else
      redirect_back fallback_location: admin_quotes_path, alert: "Could not load template."
    end
  end

  def show
    @calculator = QuoteCalculator.new(@quote).calculate
  end

  def new
    @quote = Quote.new(
      client_id: params[:client_id],
      project_id: params[:project_id],
      tax_rate: 0.06,
      valid_until: 30.days.from_now.to_date
    )
    @clients = Client.alphabetical
    @projects = @quote.client_id ? Project.where(client_id: @quote.client_id).recent : []
  end

  def create
    @quote = Quote.new(quote_params)
    @quote.version_number = 1
    @quote.status = :draft
    if @quote.save
      redirect_to admin_quote_path(@quote), notice: "Quote created."
    else
      @clients = Client.alphabetical
      @projects = @quote.client_id ? Project.where(client_id: @quote.client_id).recent : []
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = Client.alphabetical
    @projects = @quote.client_id ? Project.where(client_id: @quote.client_id).recent : []
  end

  def update
    if @quote.update(quote_params)
      redirect_to admin_quote_path(@quote), notice: "Quote updated."
    else
      @clients = Client.alphabetical
      @projects = @quote.client_id ? Project.where(client_id: @quote.client_id).recent : []
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quote.destroy
    redirect_to admin_quotes_path, notice: "Quote removed."
  end

  def send_quote
    @quote.update!(status: :sent, sent_at: Time.current)
    QuoteMailer.send_quote(@quote).deliver_later
    redirect_to admin_quote_path(@quote), notice: "Quote sent to #{@quote.client.display_name}."
  end

  def preview
    @calculator = QuoteCalculator.new(@quote).calculate
    render layout: "admin"
  end

  def save_as_template
    @quote.update!(is_template: true)
    redirect_to admin_quote_path(@quote), notice: "Quote saved as template."
  end

  # Convert an approved quote into a project
  def convert_to_project
    if @quote.project.present?
      redirect_to admin_quote_path(@quote), notice: "Quote already linked to a project."
      return
    end

    project = Project.create!(
      client: @quote.client,
      title: "Project for #{@quote.client.display_name}",
      status: :discovery
    )
    @quote.update!(project: project)
    redirect_to admin_project_path(project), notice: "Project created from quote."
  end

  private

  def set_quote
    @quote = Quote.includes(quote_line_items: [ :product, :window, :swatch ]).find(params[:id])
  end

  def quote_params
    params.require(:quote).permit(
      :client_id, :project_id, :promo_code_id, :status, :notes,
      :quote_discount_type, :quote_discount_value, :quote_discount_reason,
      :tax_rate, :deposit_percentage, :valid_until
    )
  end
end
```

**Step 6: Update quote views** — replace all `admin_project_quote_path(project, quote)` with `admin_quote_path(quote)`:
- `app/views/admin/quotes/show.html.erb` — breadcrumb, all action buttons
- `app/views/admin/quotes/_form.html.erb` — form URL, cancel link
- `app/views/admin/quotes/new.html.erb`, `edit.html.erb`, `index.html.erb`
- `app/views/admin/quote_line_items/` — all nested paths become `admin_quote_quote_line_item_path(@quote, item)`
- `app/views/admin/projects/show.html.erb` — quote links use `admin_quote_path(quote)`

**Step 7: Update quote form** — add project dropdown (optional):

```erb
<%# app/views/admin/quotes/_form.html.erb %>
<%= form_with model: [:admin, @quote], class: "space-y-6" do |f| %>
  <%= render "admin/clients/client_dropdown", form: f, field_name: :client_id, selected_id: @quote.client_id || params[:new_client_id], clients: @clients, return_to: request.fullpath %>

  <% if @projects.any? %>
    <div>
      <%= f.label :project_id, "Project (optional)", class: "block text-sm font-medium text-gray-700 mb-1" %>
      <%= f.collection_select :project_id, @projects, :id, :title,
            { prompt: "Standalone quote (no project)" },
            class: "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500" %>
    </div>
  <% end %>

  <%# ... existing tax_rate, deposit, valid_until, notes fields ... %>
<% end %>
```

**Step 8: Update admin project show page** — link to unnested quotes:

```erb
<%# In admin/projects/show.html.erb — replace admin_project_quote_path with admin_quote_path %>
<%= link_to "New Quote", new_admin_quote_path(project_id: @project.id, client_id: @project.client_id), ... %>
<%= link_to "View all", admin_quotes_path(project_id: @project.id), ... %>
<%= link_to admin_quote_path(quote), ... %>  <%# was admin_project_quote_path(@project, quote) %>
```

**Step 9: Update client portal routes** — unnest from project:

```ruby
# config/routes.rb — client namespace
namespace :client do
  resources :quotes, only: [ :show ] do
    member do
      post :approve
    end
    resources :quote_line_items, only: [] do
      member do
        post :approve, action: :approve_line_item
        post :decline, action: :decline_line_item
      end
    end
  end
  resources :projects, only: [ :index, :show ]
end
```

Update `Client::QuotesController` to use `params[:id]` for quote (no longer nested under project). Also fix the `approve_line_item`/`decline_line_item` param mismatch (`params[:id]` → `params[:line_item_id]` stays, but the route now passes it correctly).

Actually — the route param mismatch needs fixing. The member routes on `quote_line_items` pass `params[:id]` (the line item ID), but the controller reads `params[:line_item_id]`. Fix the controller:

```ruby
# app/controllers/client/quotes_controller.rb
def approve_line_item
  authorize @quote, policy_class: Client::QuotePolicy
  item = @quote.quote_line_items.find(params[:id])  # was: params[:line_item_id]
  item.update!(status: :approved)
  redirect_to client_quote_path(@quote), notice: "#{item.product&.name || 'Item'} approved."
end

def decline_line_item
  authorize @quote, policy_class: Client::QuotePolicy
  item = @quote.quote_line_items.find(params[:id])  # was: params[:line_item_id]
  item.update!(status: :declined)
  redirect_to client_quote_path(@quote), notice: "#{item.product&.name || 'Item'} declined."
end

private

def set_quote
  @quote = Quote.includes(quote_line_items: [ :product, :window, :swatch ]).find(params[:id])
  # @project removed — quote may not have one
end
```

Update `Client::QuotePolicy` to check `record.client_id == user.client_id` (was `user.id`).

**Step 10: Run rubocop + commit**

```bash
bundle exec rubocop -a
git add app/controllers/ app/models/ app/views/ config/routes.rb db/
git commit -m "feat: quotes unnested from projects — standalone quotes supported"
```

---

### Task 7: Add "Convert to Project" button on approved quotes

**Objective:** One-click project creation from an approved quote.

**Files:**
- Modify: `app/views/admin/quotes/show.html.erb`

**Step 1: Add button** — next to "Create PO":

```erb
<%# In admin/quotes/show.html.erb — action button area %>
<% if @quote.approved? && @quote.project.nil? %>
  <%= button_to "Start Project", convert_to_project_admin_quote_path(@quote), method: :post,
        class: "bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold px-4 py-2 rounded-lg transition-colors" %>
<% end %>
```

**Step 2: Commit** (included in Task 6 commit or separate)

---

## Phase 3: Fix PurchaseOrder Client Linkage

### Task 8: Add client_id to PurchaseOrder, make quote_id nullable

**Objective:** PO always has a client, optionally has a quote and project.

**Files:**
- Create: `db/migrate/{timestamp}_add_client_to_purchase_orders.rb`
- Modify: `app/models/purchase_order.rb`
- Modify: `app/controllers/admin/purchase_orders_controller.rb`
- Modify: `app/views/admin/purchase_orders/_form.html.erb`

**Step 1: Migration**

```ruby
class AddClientToPurchaseOrders < ActiveRecord::Migration[8.1]
  def up
    add_reference :purchase_orders, :client, foreign_key: true, null: true
    add_index :purchase_orders, :client_id

    # Backfill: set client_id from the linked quote's client
    PurchaseOrder.find_each do |po|
      next unless po.quote_id.present?
      quote = Quote.find_by(id: po.quote_id)
      next unless quote&.client_id.present?
      po.update_column(:client_id, quote.client_id)
    end

    change_column_null :purchase_orders, :client_id, false
    change_column_null :purchase_orders, :quote_id, true
    change_column_null :purchase_order_line_items, :quote_line_item_id, true
    change_column_null :purchase_order_line_items, :product_id, true
  end

  def down
    remove_reference :purchase_orders, :client
    change_column_null :purchase_orders, :quote_id, false
  end
end
```

**Step 2: Run migration**

```bash
unset DATABASE_URL && bin/rails db:migrate
```

**Step 3: Update PurchaseOrder model**

```ruby
# app/models/purchase_order.rb
class PurchaseOrder < ApplicationRecord
  belongs_to :client
  belongs_to :manufacturer
  belongs_to :quote, optional: true
  belongs_to :project, optional: true
  has_many :purchase_order_line_items, dependent: :destroy
  has_many :quote_line_items, through: :purchase_order_line_items

  # ... rest stays
end
```

**Step 4: Update PO controller** — when creating from a quote, inherit client:

```ruby
# In Admin::PurchaseOrdersController#create
def create
  @purchase_order = PurchaseOrder.new(po_params)
  @purchase_order.status = :draft
  @purchase_order.order_date = Date.current

  # If quote_id present, inherit client from quote
  if params[:purchase_order][:quote_id].present?
    quote = Quote.find(params[:purchase_order][:quote_id])
    @purchase_order.client_id ||= quote.client_id
    @purchase_order.project_id ||= quote.project_id
  end

  # ... rest of create
end

def po_params
  params.require(:purchase_order).permit(
    :client_id, :manufacturer_id, :quote_id, :project_id, :status,
    :order_date, :expected_delivery, :actual_delivery, :notes
  )
end
```

**Step 5: Update PO form** — add client dropdown:

```erb
<%# In admin/purchase_orders/_form.html.erb — add at top %>
<%= render "admin/clients/client_dropdown", form: f, field_name: :client_id, selected_id: @purchase_order.client_id, clients: @clients, return_to: request.fullpath %>
```

Load `@clients = Client.alphabetical` in new/edit actions.

**Step 6: Commit**

```bash
bundle exec rubocop -a
git add app/models/ app/controllers/ app/views/ db/
git commit -m "feat: PurchaseOrder always has client, optional quote — nullability fixed"
```

---

## Phase 4: Admin Sidebar Regrouping + Dashboard Reorder

### Task 9: Regroup admin sidebar

**Objective:** Reduce sidebar from ~20 flat links to grouped sections. Nested resources (rooms, windows, mood boards, etc.) removed from sidebar — accessed from parent show pages.

**Files:**
- Modify: `app/views/admin/shared/_sidebar.html.erb`

**Step 1: Rewrite sidebar**

```erb
<%
  nav_link = ->(path, active) {
    base = "flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-colors"
    active ? "#{base} bg-theme-400 text-white" : "#{base} text-theme-100 hover:bg-white/10 hover:text-white"
  }
%>
<aside class="w-64 bg-theme-500 flex flex-col flex-shrink-0">
  <div class="px-6 py-6 border-b border-white/10">
    <p class="font-serif text-xl font-semibold text-white">Brooke &amp; Maisy</p>
    <p class="text-xs uppercase tracking-[0.18em] text-theme-200 mt-0.5">Admin</p>
  </div>

  <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
    <%= link_to "Dashboard", admin_root_path, class: nav_link.call(admin_root_path, request.path == admin_root_path) %>

    <p class="px-4 pt-4 pb-1 text-[11px] font-semibold uppercase tracking-wider text-theme-300">Sales</p>
    <%= link_to "Clients", admin_clients_path, class: nav_link.call(admin_clients_path, request.path.start_with?(admin_clients_path)) %>
    <%= link_to "Quotes", admin_quotes_path, class: nav_link.call(admin_quotes_path, request.path.start_with?("/admin/quotes")) %>
    <%= link_to "Templates", admin_quote_templates_path, class: nav_link.call(admin_quote_templates_path, request.path.start_with?("/admin/templates")) %>

    <p class="px-4 pt-4 pb-1 text-[11px] font-semibold uppercase tracking-wider text-theme-300">Projects</p>
    <%= link_to "All Projects", admin_projects_path, class: nav_link.call(admin_projects_path, request.path.start_with?(admin_projects_path)) %>

    <p class="px-4 pt-4 pb-1 text-[11px] font-semibold uppercase tracking-wider text-theme-300">Procurement</p>
    <%= link_to "Purchase Orders", admin_purchase_orders_path, class: nav_link.call(admin_purchase_orders_path, request.path.start_with?(admin_purchase_orders_path)) %>
    <%= link_to "Manufacturers", admin_manufacturers_path, class: nav_link.call(admin_manufacturers_path, request.path.start_with?(admin_manufacturers_path)) %>
    <%= link_to "Products", admin_products_path, class: nav_link.call(admin_products_path, request.path.start_with?(admin_products_path)) %>
    <%= link_to "Swatches", admin_swatches_path, class: nav_link.call(admin_swatches_path, request.path.start_with?(admin_swatches_path)) %>
    <%= link_to "Promo Codes", admin_promo_codes_path, class: nav_link.call(admin_promo_codes_path, request.path.start_with?(admin_promo_codes_path)) %>

    <p class="px-4 pt-4 pb-1 text-[11px] font-semibold uppercase tracking-wider text-theme-300">Website</p>
    <% unread = Message.unread.count %>
    <%= link_to admin_messages_path, class: nav_link.call(admin_messages_path, request.path.start_with?(admin_messages_path)) do %>
      Messages
      <% if unread > 0 %>
        <span class="ml-auto bg-theme-400 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full"><%= unread %></span>
      <% end %>
    <% end %>
    <% unread_questionnaires = QuestionnaireSubmission.unread.count %>
    <%= link_to admin_questionnaire_submissions_path, class: nav_link.call(admin_questionnaire_submissions_path, request.path.start_with?(admin_questionnaire_submissions_path)) do %>
      Inquiries
      <% if unread_questionnaires > 0 %>
        <span class="ml-auto bg-theme-400 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full"><%= unread_questionnaires %></span>
      <% end %>
    <% end %>
    <%= link_to "Trade Network", admin_trade_partners_path, class: nav_link.call(admin_trade_partners_path, request.path.start_with?(admin_trade_partners_path)) %>
    <%= link_to "Services", admin_services_path, class: nav_link.call(admin_services_path, request.path.start_with?(admin_services_path)) %>

    <p class="px-4 pt-4 pb-1 text-[11px] font-semibold uppercase tracking-wider text-theme-300">Settings</p>
    <%= link_to "Markup &amp; Margins", margins_admin_settings_path, class: nav_link.call(margins_admin_settings_path, request.path.start_with?("/admin/settings")) %>
    <%= link_to "Checklist Items", admin_checklist_items_path, class: nav_link.call(admin_checklist_items_path, request.path.start_with?(admin_checklist_items_path)) %>
    <%= link_to "Categories", admin_product_categories_path, class: nav_link.call(admin_product_categories_path, request.path.start_with?(admin_product_categories_path)) %>
  </nav>

  <div class="px-4 py-4 border-t border-white/10">
    <p class="text-sm text-white font-medium"><%= current_user.display_name %></p>
    <p class="text-xs text-theme-200 mb-3 truncate"><%= current_user.email %></p>
    <div class="flex flex-col gap-1.5">
      <%= link_to "View site", root_path, class: "text-xs text-theme-200 hover:text-white" %>
      <%= button_to "Sign out", destroy_user_session_path, method: :delete,
            class: "text-left text-xs text-theme-200 hover:text-white bg-transparent border-0 p-0 cursor-pointer" %>
    </div>
  </div>
</aside>
```

**Step 2: Commit**

```bash
git add app/views/admin/shared/_sidebar.html.erb
git commit -m "feat: regroup admin sidebar — Sales, Projects, Procurement, Website, Settings"
```

---

### Task 10: Reorder admin dashboard — "New Quote" primary action

**Objective:** The admin landing page leads with the primary action, not monthly stats.

**Files:**
- Modify: `app/views/admin/dashboard/index.html.erb`
- Modify: `app/controllers/admin/dashboard_controller.rb`

**Step 1: Update dashboard controller** — add recent quotes:

```ruby
# app/controllers/admin/dashboard_controller.rb
def index
  @client_count       = Client.count
  @project_count      = Project.count
  @active_count       = Project.where.not(status: "complete").count
  @complete_count     = Project.where(status: "complete").count
  @quote_count        = Quote.live.count
  @unread_messages    = Message.unread.count
  @unread_questionnaires = QuestionnaireSubmission.unread.count
  @recent_quotes      = Quote.live.includes(:client, :project).recent.limit(5)
  @recent_projects    = Project.includes(:client).recent.limit(5)
  @recent_updates     = ProjectUpdate.includes(:project).recent.limit(5)
  @status_breakdown   = Project.group(:status).count
end
```

**Step 2: Rewrite dashboard view** — primary CTA at top:

```erb
<% content_for(:title, "Dashboard - Brooke & Maisy Admin") %>

<div class="mb-8">
  <h1 class="font-serif text-3xl font-semibold text-theme-500">Dashboard</h1>
  <p class="text-gray-500 mt-1">Overview of your design business.</p>
</div>

<%# Primary action %>
<div class="mb-8">
  <%= link_to new_admin_quote_path, class: "inline-flex items-center gap-2 bg-theme-500 hover:bg-theme-400 text-white text-lg font-semibold px-8 py-4 rounded-xl transition-colors shadow-sm" do %>
    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>
    New Quote
  <% end %>
</div>

<%# Recent quotes (primary surface) %>
<div class="bg-white rounded-xl border border-theme-100 mb-8">
  <div class="flex items-center justify-between px-5 py-4 border-b border-theme-100">
    <h2 class="font-serif text-lg font-semibold text-theme-500">Recent Quotes</h2>
    <%= link_to "View all", admin_quotes_path, class: "text-sm text-theme-500 hover:text-theme-400 font-medium" %>
  </div>
  <% if @recent_quotes.any? %>
    <ul>
      <% @recent_quotes.each do |quote| %>
        <li class="border-b border-gray-50 last:border-0">
          <%= link_to admin_quote_path(quote), class: "flex items-center justify-between px-5 py-3 hover:bg-theme-100" do %>
            <div>
              <p class="text-sm font-medium text-theme-500">Quote #<%= quote.id %> — <%= quote.client.display_name %></p>
              <p class="text-xs text-gray-400"><%= quote.quote_line_items.count %> items · v<%= quote.version_number %></p>
            </div>
            <%= render "admin/shared/status_badge", status: quote.status %>
          <% end %>
        </li>
      <% end %>
    </ul>
  <% else %>
    <p class="px-5 py-6 text-sm text-gray-400">No quotes yet.</p>
  <% end %>
</div>

<%# Stat cards (secondary) %>
<div class="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
  <%# ... existing stat cards ... %>
</div>

<%# Recent projects + updates (below) %>
<div class="grid lg:grid-cols-2 gap-6">
  <%# ... existing recent projects and updates ... %>
</div>
```

**Step 3: Commit**

```bash
git add app/controllers/admin/dashboard_controller.rb app/views/admin/dashboard/index.html.erb
git commit -m "feat: admin dashboard leads with New Quote CTA + recent quotes"
```

---

## Phase 5: Security-Gated Margin View (Presentation Mode)

### Task 11: Create margin_unlock Stimulus controller

**Objective:** Admin quote show defaults to retail-only. A "Reveal Margins" button prompts for a PIN. On correct PIN, cost/margin/profit sections become visible for the session.

**Files:**
- Create: `app/javascript/controllers/margin_unlock_controller.js`
- Modify: `app/views/admin/quotes/show.html.erb`

**Step 1: Create Stimulus controller**

```javascript
// app/javascript/controllers/margin_unlock_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "locked", "unlockButton" ]

  connect() {
    // Check if already unlocked this session
    if (sessionStorage.getItem("marginsUnlocked") === "true") {
      this.unlock()
    }
  }

  prompt(event) {
    event.preventDefault()
    const pin = prompt("Enter PIN to view margins:")
    if (pin === null) return

    // The PIN is injected from a meta tag set by the server
    const expectedPin = document.querySelector('meta[name="margin-pin"]')?.content
    if (pin === expectedPin) {
      sessionStorage.setItem("marginsUnlocked", "true")
      this.unlock()
    } else {
      alert("Incorrect PIN.")
    }
  }

  unlock() {
    this.lockedTargets.forEach(el => el.classList.remove("hidden"))
    this.unlockButtonTarget.classList.add("hidden")
  }

  lock() {
    sessionStorage.removeItem("marginsUnlocked")
    this.lockedTargets.forEach(el => el.classList.add("hidden"))
    this.unlockButtonTarget.classList.remove("hidden")
  }
}
```

**Step 2: Set the PIN via env var** — in `config/application.rb` or a Rails initializer:

```ruby
# config/initializers/margin_pin.rb
Rails.application.config.margin_pin = ENV.fetch("MARGIN_PIN", "1234")
```

In `app/views/layouts/admin.html.erb` — add meta tag in `<head>`:

```erb
<%= tag.meta name: "margin-pin", content: Rails.application.config.margin_pin %>
```

**Step 3: Modify admin quote show view** — wrap cost/margin sections:

```erb
<%# app/views/admin/quotes/show.html.erb %>
<div data-controller="margin-unlock">
  <%# ... breadcrumb and header ... %>

  <%# Reveal button (visible when locked) %>
  <div data-margin-unlock-target="unlockButton" class="mb-4">
    <button data-action="click->margin-unlock#prompt"
      class="bg-gray-100 hover:bg-gray-200 text-gray-600 text-sm font-medium px-4 py-2 rounded-lg">
      Reveal Margins
    </button>
  </div>

  <%# Line items table — wrap the cost column %>
  <%# The "Unit Cost" column header and cells get: data-margin-unlock-target="locked" class="hidden" %>

  <div class="grid grid-cols-12 px-5 py-2 bg-gray-50 text-[10px] font-semibold uppercase tracking-wider text-gray-400">
    <div class="col-span-4">Product</div>
    <div class="col-span-2">Qty</div>
    <div class="col-span-2 hidden" data-margin-unlock-target="locked">Unit Cost</div>
    <div class="col-span-2">Unit Price</div>
    <div class="col-span-2">Line Total</div>
  </div>
  <%# ... each row: add "hidden" + data-margin-unlock-target="locked" to the cost cell ... %>

  <%# Cost & Revenue card — wrap entirely %>
  <div data-margin-unlock-target="locked" class="hidden">
    <div class="bg-white rounded-xl border border-theme-100 p-6">
      <h3>Cost &amp; Revenue</h3>
      <%# ... existing cost/revenue content ... %>
    </div>
  </div>

  <%# Profit card — wrap entirely %>
  <div data-margin-unlock-target="locked" class="hidden">
    <div class="bg-white rounded-xl border border-theme-100 p-6">
      <h3>Profit</h3>
      <%# ... existing profit content ... %>
    </div>
  </div>

  <%# Line item profitability table — wrap entirely %>
  <div data-margin-unlock-target="locked" class="hidden">
    <%# ... existing profitability table ... %>
  </div>
</div>
```

**Step 4: Commit**

```bash
git add app/javascript/controllers/margin_unlock_controller.js app/views/admin/quotes/show.html.erb config/initializers/margin_pin.rb app/views/layouts/admin.html.erb
git commit -m "feat: admin quote view defaults to presentation mode — margins behind PIN unlock"
```

---

## Phase 6: Cleanup

### Task 12: Remove dead admin Pundit policies

**Files to delete:**
- `app/policies/admin/quote_policy.rb` (if exists)
- Any policy under `app/policies/admin/` that is never called
- `app/policies/checklist_item_policy.rb` (has broken Scope constant)

Keep: `Client::QuotePolicy`, `Client::ProjectPolicy`, `Tech::DashboardPolicy`, `ApplicationPolicy`.

**Step 1: Identify dead policies**

```bash
grep -rl "authorize" app/controllers/  # find which controllers actually call authorize
```

Any policy file not referenced by a controller `authorize` call is dead.

**Step 2: Delete dead policy files**

```bash
git rm app/policies/admin/quote_policy.rb  # etc.
```

**Step 3: Add authorize to Tech::DashboardController**

```ruby
# app/controllers/tech/dashboard_controller.rb
class Tech::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_dashboard

  def show
    @projects = Project.recent
    @checklist_items = ChecklistItem.active.ordered
  end

  private

  def authorize_dashboard
    authorize :dashboard, policy_class: Tech::DashboardPolicy
  end
end
```

Actually — `Tech::DashboardPolicy` has no `show?` method. Simplify: just add `authorize` with a policy that checks `user.tech?`:

```ruby
# app/policies/tech/dashboard_policy.rb
class Tech::DashboardPolicy < ApplicationPolicy
  def show?
    user&.tech?
  end
end
```

```ruby
# In Tech::DashboardController#show
authorize :dashboard, policy_class: Tech::DashboardPolicy
```

**Step 4: Commit**

```bash
git add app/controllers/ app/policies/
git commit -m "chore: remove dead admin Pundit policies, wire Tech::DashboardController#authorize"
```

---

### Task 13: Add missing unique indexes

**Files:**
- Create: `db/migrate/{timestamp}_add_unique_indexes.rb`

```ruby
class AddUniqueIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :manufacturers, :name, unique: true
    add_index :product_categories, :slug, unique: true
    add_index :product_categories, [ :parent_id, :name ], unique: true, name: "index_product_categories_on_parent_and_name"
    add_index :promo_codes, :code, unique: true
    add_index :product_swatches, [ :product_id, :swatch_id ], unique: true, name: "index_product_swatches_on_product_and_swatch"
  end
end
```

```bash
unset DATABASE_URL && bin/rails db:migrate
git add db/ && git commit -m "fix: add unique DB indexes backing validates uniqueness"
```

---

### Task 14: Add missing status_badge entries + presence validations

**Files:**
- Modify: `app/views/admin/shared/_status_badge.html.erb`
- Modify: `app/models/window.rb`
- Modify: `app/models/quote.rb`
- Modify: `app/models/purchase_order.rb`

**Step 1: Add PO line item statuses to shared partial** (or create dedicated partial):

```erb
<%# In _status_badge.html.erb — add: %>
<% when "pending" then "bg-yellow-100 text-yellow-800" %>
<% when "backordered" then "bg-red-100 text-red-800" %>
<% when "received" then "bg-gray-100 text-gray-600" %>
```

**Step 2: Add presence validations:**

```ruby
# app/models/window.rb
validates :width, presence: true, numericality: { greater_than: 0 }
validates :height, presence: true, numericality: { greater_than: 0 }

# app/models/quote.rb
validates :valid_until, presence: true

# app/models/purchase_order.rb
validates :order_date, presence: true
```

**Step 3: Commit**

```bash
bundle exec rubocop -a
git add app/models/ app/views/admin/shared/
git commit -m "fix: add missing validations + status_badge entries"
```

---

### Task 15: Final rubocop + brakeman + boot test

```bash
unset DATABASE_URL
bundle exec rubocop
bundle exec brakeman
bin/rails test
# Boot the server and manually verify:
# 1. Admin dashboard shows "New Quote" button
# 2. New quote form lets you pick client (from Client model, no email required)
# 3. Quote show defaults to retail-only, "Reveal Margins" behind PIN
# 4. Sidebar is grouped
# 5. Convert to project works on approved quote
# 6. Create PO works with and without a quote
```

```bash
git add . && git commit -m "chore: final lint + boot verification"
```

---

## Summary

| Phase | Tasks | What it delivers |
|---|---|---|
| 1 | Tasks 1–5 | Client model decoupled from User. No email required to create a client. Invite-to-portal is a separate button. |
| 2 | Tasks 6–7 | Quotes are standalone (unnested from projects). New quote form picks a client, optionally a project. "Convert to project" on approved quotes. |
| 3 | Task 8 | PurchaseOrder always has a client. Quote is optional. Nullability conflict resolved. |
| 4 | Tasks 9–10 | Sidebar grouped (5 sections). Dashboard leads with "New Quote" CTA + recent quotes. |
| 5 | Task 11 | Admin quote view defaults to presentation (retail-only). Margins behind session-pinned Stimulus unlock. |
| 6 | Tasks 12–15 | Dead Pundit policies removed. Unique indexes added. Validations + status_badge gaps filled. Final lint + boot. |

**Total: 15 tasks across 6 phases.**

**Environment variable needed:** `MARGIN_PIN` — set in Heroku config and `.env` for dev. Default is "1234" if unset.

**Data migrations:** Tasks 3 and 4 backfill existing data (User → Client). No data loss. The old `user_id` column on projects is kept but unused; a future cleanup migration can remove it.
