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

ActiveRecord::Schema[8.1].define(version: 2026_06_05_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "collection_logs", force: :cascade do |t|
    t.string "api_id"
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}, null: false
    t.string "endpoint"
    t.string "level", default: "info", null: false
    t.bigint "market_snapshot_id"
    t.text "message"
    t.datetime "occurred_at", null: false
    t.integer "response_code"
    t.string "stage", null: false
    t.datetime "updated_at", null: false
    t.index ["level", "stage"], name: "index_collection_logs_on_level_and_stage"
    t.index ["market_snapshot_id", "occurred_at"], name: "index_collection_logs_on_market_snapshot_id_and_occurred_at"
    t.index ["market_snapshot_id"], name: "index_collection_logs_on_market_snapshot_id"
  end

  create_table "daily_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "execution_strength", precision: 10, scale: 2
    t.bigint "foreign_net_purchase"
    t.bigint "individual_net_purchase"
    t.bigint "institution_net_purchase"
    t.date "metric_date", null: false
    t.bigint "pension_net_purchase"
    t.jsonb "raw_investor_payload", default: {}, null: false
    t.jsonb "raw_strength_payload", default: {}, null: false
    t.bigint "snapshot_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["snapshot_item_id", "metric_date"], name: "index_daily_metrics_on_snapshot_item_id_and_metric_date", unique: true
    t.index ["snapshot_item_id"], name: "index_daily_metrics_on_snapshot_item_id"
  end

  create_table "leader_selections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "market_snapshot_id", null: false
    t.bigint "sector_id", null: false
    t.bigint "stock_id", null: false
    t.datetime "updated_at", null: false
    t.index ["market_snapshot_id", "sector_id"], name: "index_leader_selections_on_market_snapshot_id_and_sector_id", unique: true
    t.index ["market_snapshot_id", "stock_id"], name: "index_leader_selections_on_market_snapshot_id_and_stock_id", unique: true
    t.index ["market_snapshot_id"], name: "index_leader_selections_on_market_snapshot_id"
    t.index ["sector_id"], name: "index_leader_selections_on_sector_id"
    t.index ["stock_id"], name: "index_leader_selections_on_stock_id"
  end

  create_table "market_snapshots", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "failed_at"
    t.text "failure_message"
    t.string "snapshot_type", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.date "trade_date", null: false
    t.datetime "updated_at", null: false
    t.index ["trade_date", "snapshot_type"], name: "index_market_snapshots_on_trade_date_and_snapshot_type", unique: true
    t.index ["trade_date", "status"], name: "index_market_snapshots_on_trade_date_and_status"
  end

  create_table "sector_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "effective_on", null: false
    t.bigint "sector_id", null: false
    t.bigint "stock_id", null: false
    t.datetime "updated_at", null: false
    t.index ["sector_id"], name: "index_sector_assignments_on_sector_id"
    t.index ["stock_id", "effective_on"], name: "index_sector_assignments_on_stock_id_and_effective_on", unique: true
    t.index ["stock_id"], name: "index_sector_assignments_on_stock_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sectors_on_name", unique: true
  end

  create_table "snapshot_items", force: :cascade do |t|
    t.decimal "change_rate", precision: 8, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "current_price", default: 0, null: false
    t.bigint "market_snapshot_id", null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.bigint "stock_id", null: false
    t.bigint "trade_value", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "volume", default: 0, null: false
    t.index ["market_snapshot_id", "stock_id"], name: "index_snapshot_items_on_market_snapshot_id_and_stock_id", unique: true
    t.index ["market_snapshot_id", "trade_value"], name: "index_snapshot_items_on_market_snapshot_id_and_trade_value"
    t.index ["market_snapshot_id"], name: "index_snapshot_items_on_market_snapshot_id"
    t.index ["stock_id"], name: "index_snapshot_items_on_stock_id"
  end

  create_table "stocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "market"
    t.string "name", null: false
    t.string "ticker", null: false
    t.datetime "updated_at", null: false
    t.index ["ticker"], name: "index_stocks_on_ticker", unique: true
  end

  add_foreign_key "collection_logs", "market_snapshots"
  add_foreign_key "daily_metrics", "snapshot_items"
  add_foreign_key "leader_selections", "market_snapshots"
  add_foreign_key "leader_selections", "sectors"
  add_foreign_key "leader_selections", "stocks"
  add_foreign_key "sector_assignments", "sectors"
  add_foreign_key "sector_assignments", "stocks"
  add_foreign_key "snapshot_items", "market_snapshots"
  add_foreign_key "snapshot_items", "stocks"
end
