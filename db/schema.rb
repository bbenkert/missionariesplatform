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

ActiveRecord::Schema[8.0].define(version: 2025_09_02_024940) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "unaccent"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.boolean "is_blocked", default: false
    t.datetime "blocked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_blocked"], name: "index_conversations_on_is_blocked"
    t.index ["recipient_id"], name: "index_conversations_on_recipient_id"
    t.index ["sender_id", "recipient_id"], name: "index_conversations_on_sender_id_and_recipient_id", unique: true
    t.index ["sender_id"], name: "index_conversations_on_sender_id"
    t.index ["updated_at"], name: "index_conversations_on_updated_at"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "followable_type", null: false
    t.bigint "followable_id", null: false
    t.boolean "notifications_enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable"
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable_type_and_followable_id"
    t.index ["user_id", "followable_type", "followable_id"], name: "index_follows_on_user_and_followable", unique: true
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "content"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["read_at"], name: "index_messages_on_read_at"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "missionary_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio"
    t.string "ministry_focus"
    t.string "organization"
    t.string "country"
    t.string "city"
    t.text "prayer_requests"
    t.text "giving_links"
    t.string "website_url"
    t.string "social_media_links"
    t.date "started_ministry_at"
    t.text "ministry_description"
    t.boolean "accepting_messages", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.boolean "sensitive_flag", default: false
    t.integer "public_profile_level", default: 0
    t.string "pseudonym"
    t.string "public_region"
    t.jsonb "safety_options", default: {}
    t.bigint "organization_id"
    t.integer "safety_mode", default: 0, null: false
    t.index ["country"], name: "index_missionary_profiles_on_country"
    t.index ["ministry_focus"], name: "index_missionary_profiles_on_ministry_focus"
    t.index ["organization"], name: "index_missionary_profiles_on_organization"
    t.index ["organization_id"], name: "index_missionary_profiles_on_organization_id"
    t.index ["public_profile_level"], name: "index_missionary_profiles_on_public_profile_level"
    t.index ["safety_mode"], name: "index_missionary_profiles_on_safety_mode"
    t.index ["safety_options"], name: "index_missionary_profiles_on_safety_options", using: :gin
    t.index ["sensitive_flag"], name: "index_missionary_profiles_on_sensitive_flag"
    t.index ["slug"], name: "index_missionary_profiles_on_slug", unique: true
    t.index ["user_id"], name: "index_missionary_profiles_on_user_id", unique: true
  end

  create_table "missionary_updates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "content"
    t.integer "update_type", default: 0
    t.integer "status", default: 0
    t.boolean "is_urgent", default: false
    t.string "tags"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0
    t.tsvector "tsvector"
    t.index ["is_urgent"], name: "index_missionary_updates_on_is_urgent"
    t.index ["published_at"], name: "index_missionary_updates_on_published_at"
    t.index ["status"], name: "index_missionary_updates_on_status"
    t.index ["tags"], name: "index_missionary_updates_on_tags"
    t.index ["tsvector"], name: "index_missionary_updates_on_tsvector", using: :gin
    t.index ["update_type"], name: "index_missionary_updates_on_update_type"
    t.index ["user_id"], name: "index_missionary_updates_on_user_id"
    t.index ["visibility"], name: "index_missionary_updates_on_visibility"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.jsonb "settings", default: {}
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name"
    t.index ["settings"], name: "index_organizations_on_settings", using: :gin
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "prayer_actions", force: :cascade do |t|
    t.bigint "prayer_request_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prayer_actions_on_created_at"
    t.index ["prayer_request_id", "user_id"], name: "index_prayer_actions_on_prayer_request_id_and_user_id", unique: true
    t.index ["prayer_request_id"], name: "index_prayer_actions_on_prayer_request_id"
    t.index ["user_id"], name: "index_prayer_actions_on_user_id"
  end

  create_table "prayer_requests", force: :cascade do |t|
    t.bigint "missionary_profile_id", null: false
    t.string "title", null: false
    t.text "body"
    t.jsonb "tags"
    t.integer "status", default: 0
    t.integer "urgency", default: 0
    t.datetime "published_at"
    t.tsvector "tsvector"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["missionary_profile_id"], name: "index_prayer_requests_on_missionary_profile_id"
    t.index ["published_at"], name: "index_prayer_requests_on_published_at"
    t.index ["status"], name: "index_prayer_requests_on_status"
    t.index ["tags"], name: "index_prayer_requests_on_tags", using: :gin
    t.index ["tsvector"], name: "index_prayer_requests_on_tsvector", using: :gin
    t.index ["urgency"], name: "index_prayer_requests_on_urgency"
  end

  create_table "supporter_followings", force: :cascade do |t|
    t.bigint "supporter_id", null: false
    t.bigint "missionary_id", null: false
    t.boolean "is_active", default: true
    t.boolean "email_notifications", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_supporter_followings_on_is_active"
    t.index ["missionary_id"], name: "index_supporter_followings_on_missionary_id"
    t.index ["supporter_id", "missionary_id"], name: "index_supporter_followings_unique", unique: true
    t.index ["supporter_id"], name: "index_supporter_followings_on_supporter_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0
    t.integer "status", default: 0
    t.boolean "is_active", default: true
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "follows", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "missionary_profiles", "organizations"
  add_foreign_key "missionary_profiles", "users"
  add_foreign_key "missionary_updates", "users"
  add_foreign_key "prayer_actions", "prayer_requests"
  add_foreign_key "prayer_actions", "users"
  add_foreign_key "prayer_requests", "missionary_profiles"
  add_foreign_key "supporter_followings", "users", column: "missionary_id"
  add_foreign_key "supporter_followings", "users", column: "supporter_id"
  add_foreign_key "users", "organizations"
end
