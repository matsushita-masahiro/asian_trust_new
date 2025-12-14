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

ActiveRecord::Schema[8.0].define(version: 2025_12_14_053310) do
  create_table "access_logs", force: :cascade do |t|
    t.string "ip_address"
    t.string "path"
    t.string "user_agent"
    t.integer "user_id"
    t.datetime "accessed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accessed_at"], name: "index_access_logs_on_accessed_at"
    t.index ["path", "accessed_at"], name: "index_access_logs_on_path_and_accessed_at"
    t.index ["user_id"], name: "index_access_logs_on_user_id"
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

  create_table "addresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "address_type", null: false
    t.string "postal_code"
    t.text "address", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_type"], name: "index_addresses_on_address_type"
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
    t.index ["user_id", "address_type"], name: "index_addresses_on_user_id_and_address_type", unique: true
    t.index ["user_id", "deleted_at"], name: "index_addresses_on_user_id_and_deleted_at"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "answers", force: :cascade do |t|
    t.integer "inquiry_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inquiry_id"], name: "index_answers_on_inquiry_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "delivery_type"
    t.integer "clinic_id"
    t.string "address_type"
    t.string "other_recipient_name"
    t.string "other_postal_code"
    t.text "other_address"
    t.string "other_phone_number"
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "clinic_reservations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "purchase_id", null: false
    t.integer "clinic_id"
    t.text "treatment_methods"
    t.date "preferred_date_1"
    t.string "preferred_time_1"
    t.date "preferred_date_2"
    t.string "preferred_time_2"
    t.date "preferred_date_3"
    t.string "preferred_time_3"
    t.text "disease_name"
    t.text "current_treatment"
    t.text "current_condition"
    t.text "questions"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "confirmed_preference"
    t.date "confirmed_date"
    t.string "confirmed_time"
    t.index ["purchase_id"], name: "index_clinic_reservations_on_purchase_id"
    t.index ["user_id"], name: "index_clinic_reservations_on_user_id"
  end

  create_table "delivery_informations", force: :cascade do |t|
    t.integer "purchase_id", null: false
    t.string "delivery_type", null: false
    t.integer "clinic_id"
    t.string "address_type"
    t.text "delivery_address"
    t.text "delivery_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recipient_name"
    t.string "postal_code"
    t.string "phone_number"
    t.index ["clinic_id"], name: "index_delivery_informations_on_clinic_id"
    t.index ["purchase_id", "delivery_type"], name: "index_delivery_informations_on_purchase_id_and_delivery_type"
    t.index ["purchase_id"], name: "index_delivery_informations_on_purchase_id"
  end

  create_table "inquiries", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_inquiries_on_user_id"
  end

  create_table "invoice_bases", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "company_name"
    t.string "postal_code"
    t.text "address"
    t.string "department"
    t.string "email"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bank_name"
    t.string "bank_branch_name"
    t.string "bank_account_type"
    t.string "bank_account_number"
    t.string "bank_account_name"
    t.index ["user_id"], name: "index_invoice_bases_on_user_id"
  end

  create_table "invoice_recipients", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.string "email"
    t.string "postal_code"
    t.string "address"
    t.string "tel"
    t.string "department"
    t.text "notes"
    t.string "representative_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bank_name"
    t.string "bank_branch_name"
    t.string "bank_account_type"
    t.string "bank_account_number"
    t.string "bank_account_name"
    t.index ["user_id"], name: "index_invoice_recipients_on_user_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "invoice_recipient_id", null: false
    t.date "invoice_date"
    t.date "due_date"
    t.integer "total_amount"
    t.string "bank_name"
    t.string "bank_branch_name"
    t.string "bank_account_type"
    t.string "bank_account_number"
    t.string "bank_account_name"
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target_month"
    t.string "invoice_number"
    t.index ["invoice_recipient_id"], name: "index_invoices_on_invoice_recipient_id"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "level_change_applications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "current_level_id", null: false
    t.integer "target_level_id", null: false
    t.integer "applicant_id", null: false
    t.text "reason", null: false
    t.string "status", default: "pending", null: false
    t.date "scheduled_date", null: false
    t.datetime "executed_at"
    t.text "error_message"
    t.string "ip_address", limit: 45
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applicant_id"], name: "index_level_change_applications_on_applicant_id"
    t.index ["current_level_id"], name: "index_level_change_applications_on_current_level_id"
    t.index ["status", "scheduled_date"], name: "idx_status_scheduled"
    t.index ["target_level_id"], name: "index_level_change_applications_on_target_level_id"
    t.index ["user_id", "status"], name: "idx_user_status"
    t.index ["user_id"], name: "index_level_change_applications_on_user_id"
  end

  create_table "levels", force: :cascade do |t|
    t.string "name", null: false
    t.integer "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["value"], name: "index_levels_on_value", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notification_type"
    t.string "title"
    t.text "message"
    t.string "link_url"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "product_prices", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "level_id"
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "wott_level_id"
    t.decimal "incentive_rate", precision: 5, scale: 2
    t.index ["level_id"], name: "index_product_prices_on_level_id"
    t.index ["product_id"], name: "index_product_prices_on_product_id"
    t.index ["wott_level_id"], name: "index_product_prices_on_wott_level_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.integer "base_price"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "unit_quantity"
    t.string "unit_label"
    t.text "description"
    t.string "short_name"
    t.datetime "deleted_at"
    t.string "category"
    t.boolean "tax_included", default: false, null: false
  end

  create_table "purchase_invoices", force: :cascade do |t|
    t.integer "purchase_id", null: false
    t.string "invoice_number"
    t.date "invoice_date"
    t.date "due_date"
    t.decimal "total_amount"
    t.integer "status"
    t.datetime "sent_at"
    t.datetime "confirmed_at"
    t.datetime "receipt_requested_at"
    t.datetime "receipt_sent_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shipping_fee", default: 0
    t.integer "admin_fee", default: 0
    t.integer "tax_amount", default: 0
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.1"
    t.integer "subtotal_before_tax", default: 0
    t.integer "total_with_tax", default: 0
    t.index ["purchase_id"], name: "index_purchase_invoices_on_purchase_id"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.integer "purchase_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "seller_price"
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "purchased_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_type", default: "cash", null: false
    t.string "status", default: "built", null: false
    t.index ["payment_type", "status"], name: "index_purchases_on_payment_type_and_status"
    t.index ["payment_type"], name: "index_purchases_on_payment_type"
    t.index ["status"], name: "index_purchases_on_status"
    t.index ["user_id"], name: "index_purchases_on_user_id"
    t.index ["user_id"], name: "index_purchases_on_user_id_and_buyer_id"
  end

  create_table "referral_invitations", force: :cascade do |t|
    t.integer "referrer_id", null: false
    t.string "referral_token", null: false
    t.integer "target_level_id", null: false
    t.string "passcode", null: false
    t.datetime "expires_at"
    t.datetime "used_at"
    t.integer "invited_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_user_id"], name: "index_referral_invitations_on_invited_user_id"
    t.index ["referral_token", "passcode"], name: "index_referral_invitations_on_referral_token_and_passcode"
    t.index ["referral_token"], name: "index_referral_invitations_on_referral_token", unique: true
    t.index ["referrer_id"], name: "index_referral_invitations_on_referrer_id"
    t.index ["target_level_id"], name: "index_referral_invitations_on_target_level_id"
  end

  create_table "shipping_fees", force: :cascade do |t|
    t.integer "purchase_id", null: false
    t.string "shipping_type"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_id"], name: "index_shipping_fees_on_purchase_id"
  end

  create_table "user_level_histories", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "level_id", null: false
    t.integer "previous_level_id"
    t.datetime "effective_from", null: false
    t.datetime "effective_to"
    t.text "change_reason", null: false
    t.integer "changed_by_id", null: false
    t.string "ip_address", limit: 45
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "wott_level_id"
    t.integer "previous_wott_level_id"
    t.index ["changed_by_id"], name: "index_user_level_histories_on_changed_by_id"
    t.index ["created_at"], name: "index_user_level_histories_on_created_at"
    t.index ["level_id"], name: "index_user_level_histories_on_level_id"
    t.index ["previous_level_id"], name: "index_user_level_histories_on_previous_level_id"
    t.index ["previous_wott_level_id"], name: "index_user_level_histories_on_previous_wott_level_id"
    t.index ["user_id", "effective_from", "effective_to"], name: "idx_user_level_histories_effective_dates"
    t.index ["user_id"], name: "index_user_level_histories_on_user_id"
    t.index ["wott_level_id"], name: "index_user_level_histories_on_wott_level_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.integer "referred_by_id"
    t.integer "level"
    t.string "lstep_user_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level_id"
    t.boolean "admin"
    t.string "status", default: "active", null: false
    t.string "referral_token"
    t.string "phone"
    t.integer "wott_level_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["level_id"], name: "index_users_on_level_id"
    t.index ["lstep_user_id"], name: "index_users_on_lstep_user_id", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["referral_token"], name: "index_users_on_referral_token"
    t.index ["referred_by_id"], name: "index_users_on_referred_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["wott_level_id"], name: "index_users_on_wott_level_id"
  end

  create_table "wott_level_upgrade_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "current_wott_level_id"
    t.integer "requested_wott_level_id"
    t.string "status", default: "pending", null: false
    t.text "admin_notes"
    t.integer "processed_by_id"
    t.datetime "processed_at"
    t.integer "purchase_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_id"], name: "index_wott_level_upgrade_requests_on_purchase_id"
    t.index ["status"], name: "index_wott_level_upgrade_requests_on_status"
    t.index ["user_id"], name: "index_wott_level_upgrade_requests_on_user_id"
  end

  create_table "wott_levels", force: :cascade do |t|
    t.string "name", null: false
    t.integer "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_wott_levels_on_name", unique: true
    t.index ["value"], name: "index_wott_levels_on_value", unique: true
  end

  add_foreign_key "access_logs", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "answers", "inquiries"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "clinic_reservations", "purchases"
  add_foreign_key "clinic_reservations", "users"
  add_foreign_key "delivery_informations", "purchases"
  add_foreign_key "delivery_informations", "users", column: "clinic_id"
  add_foreign_key "inquiries", "users"
  add_foreign_key "invoice_bases", "users"
  add_foreign_key "invoice_recipients", "users"
  add_foreign_key "invoices", "invoice_recipients"
  add_foreign_key "invoices", "users"
  add_foreign_key "level_change_applications", "levels", column: "current_level_id"
  add_foreign_key "level_change_applications", "levels", column: "target_level_id"
  add_foreign_key "level_change_applications", "users"
  add_foreign_key "level_change_applications", "users", column: "applicant_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "product_prices", "levels"
  add_foreign_key "product_prices", "products"
  add_foreign_key "product_prices", "wott_levels"
  add_foreign_key "purchase_invoices", "purchases"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "users"
  add_foreign_key "referral_invitations", "levels", column: "target_level_id"
  add_foreign_key "referral_invitations", "users", column: "invited_user_id"
  add_foreign_key "referral_invitations", "users", column: "referrer_id"
  add_foreign_key "shipping_fees", "purchases"
  add_foreign_key "user_level_histories", "levels"
  add_foreign_key "user_level_histories", "levels", column: "previous_level_id"
  add_foreign_key "user_level_histories", "users"
  add_foreign_key "user_level_histories", "users", column: "changed_by_id"
  add_foreign_key "user_level_histories", "wott_levels"
  add_foreign_key "user_level_histories", "wott_levels", column: "previous_wott_level_id"
  add_foreign_key "users", "levels"
  add_foreign_key "users", "wott_levels"
  add_foreign_key "wott_level_upgrade_requests", "purchases"
  add_foreign_key "wott_level_upgrade_requests", "users"
end
