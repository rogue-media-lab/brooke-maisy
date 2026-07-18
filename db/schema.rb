# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_18_201721) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "checklist_items", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "clients", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_clients_on_email"
    t.index ["name"], name: "index_clients_on_name"
  end

  create_table "color_swatches", force: :cascade do |t|
    t.string "brand"
    t.datetime "created_at", null: false
    t.bigint "design_presentation_id", null: false
    t.string "finish"
    t.string "hex_code", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "room"
    t.datetime "updated_at", null: false
    t.index ["design_presentation_id"], name: "index_color_swatches_on_design_presentation_id"
  end

  create_table "design_presentations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "project_id", null: false
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "status"], name: "index_design_presentations_on_project_id_and_status"
    t.index ["project_id"], name: "index_design_presentations_on_project_id"
  end

  create_table "manufacturers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "markup_override"
    t.string "name"
    t.text "notes"
    t.decimal "trade_discount"
    t.string "trade_program_url"
    t.datetime "updated_at", null: false
    t.string "website"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.boolean "read", default: false
    t.string "service"
    t.datetime "updated_at", null: false
  end

  create_table "mood_board_items", force: :cascade do |t|
    t.string "caption"
    t.string "category"
    t.datetime "created_at", null: false
    t.bigint "mood_board_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["mood_board_id"], name: "index_mood_board_items_on_mood_board_id"
  end

  create_table "mood_boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_presentation_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["design_presentation_id"], name: "index_mood_boards_on_design_presentation_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "markup_override"
    t.string "name"
    t.bigint "parent_id"
    t.string "slug"
    t.string "spec_template"
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
  end

  create_table "product_selections", force: :cascade do |t|
    t.text "client_notes"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "design_presentation_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.decimal "price", precision: 10, scale: 2
    t.string "product_url"
    t.integer "quantity"
    t.string "room"
    t.string "status", default: "proposed", null: false
    t.datetime "updated_at", null: false
    t.string "vendor"
    t.index ["design_presentation_id"], name: "index_product_selections_on_design_presentation_id"
  end

  create_table "product_swatches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "swatch_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_swatches_on_product_id"
    t.index ["swatch_id"], name: "index_product_swatches_on_swatch_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "documents"
    t.jsonb "images"
    t.boolean "is_active"
    t.integer "lead_time_days"
    t.bigint "manufacturer_id", null: false
    t.string "name"
    t.text "notes"
    t.jsonb "pricing"
    t.bigint "product_category_id", null: false
    t.string "product_url"
    t.jsonb "specs"
    t.integer "tier"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.jsonb "videos"
    t.index ["manufacturer_id"], name: "index_products_on_manufacturer_id"
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
  end

  create_table "project_updates", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible_to_client", default: true, null: false
    t.index ["project_id"], name: "index_project_updates_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "address"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "status", default: "discovery", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "promo_codes", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "discount_type"
    t.decimal "discount_value"
    t.date "expires_at"
    t.boolean "is_active"
    t.decimal "min_purchase"
    t.datetime "updated_at", null: false
    t.integer "usage_count"
    t.integer "usage_limit"
  end

  create_table "purchase_order_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "manufacturer_sku"
    t.bigint "product_id"
    t.bigint "purchase_order_id", null: false
    t.integer "quantity"
    t.bigint "quote_line_item_id"
    t.integer "status"
    t.decimal "total_cost"
    t.decimal "unit_cost"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_order_line_items_on_product_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_line_items_on_purchase_order_id"
    t.index ["quote_line_item_id"], name: "index_purchase_order_line_items_on_quote_line_item_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.date "actual_delivery"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.date "expected_delivery"
    t.bigint "manufacturer_id", null: false
    t.text "notes"
    t.date "order_date"
    t.bigint "quote_id"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_purchase_orders_on_client_id"
    t.index ["manufacturer_id"], name: "index_purchase_orders_on_manufacturer_id"
    t.index ["quote_id"], name: "index_purchase_orders_on_quote_id"
  end

  create_table "questionnaire_submissions", force: :cascade do |t|
    t.jsonb "answers"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.string "preferred_contact"
    t.boolean "read", default: false, null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_questionnaire_submissions_on_created_at"
    t.index ["email"], name: "index_questionnaire_submissions_on_email"
    t.index ["status"], name: "index_questionnaire_submissions_on_status"
  end

  create_table "quote_line_items", force: :cascade do |t|
    t.string "comparison_group"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "discount_reason"
    t.string "discount_type"
    t.decimal "discount_value"
    t.decimal "height"
    t.decimal "line_total"
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.bigint "product_id"
    t.integer "quantity", default: 1, null: false
    t.bigint "quote_id", null: false
    t.jsonb "selected_options"
    t.integer "status", default: 0, null: false
    t.bigint "swatch_id"
    t.decimal "unit_cost"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.decimal "width"
    t.bigint "window_id"
    t.index ["product_id"], name: "index_quote_line_items_on_product_id"
    t.index ["quote_id"], name: "index_quote_line_items_on_quote_id"
    t.index ["swatch_id"], name: "index_quote_line_items_on_swatch_id"
    t.index ["window_id"], name: "index_quote_line_items_on_window_id"
  end

  create_table "quote_revisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "quote_id", null: false
    t.jsonb "snapshot"
    t.datetime "updated_at", null: false
    t.integer "version_number"
    t.index ["quote_id"], name: "index_quote_revisions_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.decimal "adjusted_subtotal"
    t.datetime "approved_at"
    t.decimal "balance_due"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.decimal "deposit_amount"
    t.decimal "deposit_percentage"
    t.decimal "grand_total"
    t.boolean "is_template"
    t.text "notes"
    t.bigint "project_id"
    t.bigint "promo_code_id"
    t.string "quote_discount_reason"
    t.string "quote_discount_type"
    t.decimal "quote_discount_value"
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal"
    t.decimal "tax_amount"
    t.decimal "tax_rate"
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.integer "version_number", default: 1, null: false
    t.index ["client_id"], name: "index_quotes_on_client_id"
    t.index ["project_id"], name: "index_quotes_on_project_id"
    t.index ["promo_code_id"], name: "index_quotes_on_promo_code_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.text "notes"
    t.integer "position"
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_rooms_on_project_id"
  end

  create_table "services", force: :cascade do |t|
    t.boolean "active", default: true
    t.text "bullet_points"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0
    t.string "icon_name"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "swatches", force: :cascade do |t|
    t.string "category"
    t.string "color_range"
    t.datetime "created_at", null: false
    t.string "hex"
    t.string "image_url"
    t.boolean "is_active"
    t.boolean "is_new"
    t.bigint "manufacturer_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["manufacturer_id"], name: "index_swatches_on_manufacturer_id"
  end

  create_table "trade_partners", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0
    t.string "email"
    t.integer "jobs_referred", default: 0
    t.string "name", null: false
    t.string "phone"
    t.decimal "rating", precision: 3, scale: 1, default: "0.0"
    t.string "trade_type", default: "other", null: false
    t.datetime "updated_at", null: false
    t.string "website"
    t.integer "years_experience", default: 0
  end

  create_table "users", force: :cascade do |t|
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "client"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_users_on_client_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "windows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "depth"
    t.decimal "height"
    t.string "mount_type"
    t.string "name"
    t.text "notes"
    t.integer "position"
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "width"
    t.index ["room_id"], name: "index_windows_on_room_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "color_swatches", "design_presentations"
  add_foreign_key "design_presentations", "projects"
  add_foreign_key "mood_board_items", "mood_boards"
  add_foreign_key "mood_boards", "design_presentations"
  add_foreign_key "product_categories", "product_categories", column: "parent_id"
  add_foreign_key "product_selections", "design_presentations"
  add_foreign_key "product_swatches", "products"
  add_foreign_key "product_swatches", "swatches"
  add_foreign_key "products", "manufacturers"
  add_foreign_key "products", "product_categories"
  add_foreign_key "project_updates", "projects"
  add_foreign_key "projects", "clients"
  add_foreign_key "projects", "users"
  add_foreign_key "purchase_order_line_items", "products"
  add_foreign_key "purchase_order_line_items", "purchase_orders"
  add_foreign_key "purchase_order_line_items", "quote_line_items"
  add_foreign_key "purchase_orders", "clients"
  add_foreign_key "purchase_orders", "manufacturers"
  add_foreign_key "purchase_orders", "quotes"
  add_foreign_key "quote_line_items", "products"
  add_foreign_key "quote_line_items", "quotes"
  add_foreign_key "quote_line_items", "swatches"
  add_foreign_key "quote_line_items", "windows"
  add_foreign_key "quote_revisions", "quotes"
  add_foreign_key "quotes", "clients"
  add_foreign_key "quotes", "projects"
  add_foreign_key "quotes", "promo_codes"
  add_foreign_key "rooms", "projects"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "swatches", "manufacturers"
  add_foreign_key "users", "clients"
  add_foreign_key "windows", "rooms"
end
