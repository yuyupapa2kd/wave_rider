class CreateMarketDashboardSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :stocks do |t|
      t.string :ticker, null: false
      t.string :name, null: false
      t.string :market
      t.timestamps

      t.index :ticker, unique: true
    end

    create_table :sectors do |t|
      t.string :name, null: false
      t.timestamps

      t.index :name, unique: true
    end

    create_table :sector_assignments do |t|
      t.references :stock, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true
      t.date :effective_on, null: false
      t.timestamps

      t.index [ :stock_id, :effective_on ], unique: true
    end

    create_table :market_snapshots do |t|
      t.date :trade_date, null: false
      t.string :snapshot_type, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :failure_message
      t.timestamps

      t.index [ :trade_date, :snapshot_type ], unique: true
      t.index [ :trade_date, :status ]
    end

    create_table :snapshot_items do |t|
      t.references :market_snapshot, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.bigint :trade_value, null: false, default: 0
      t.integer :volume, null: false, default: 0
      t.integer :current_price, null: false, default: 0
      t.decimal :change_rate, precision: 8, scale: 4, null: false, default: 0
      t.jsonb :raw_payload, null: false, default: {}
      t.timestamps

      t.index [ :market_snapshot_id, :stock_id ], unique: true
      t.index [ :market_snapshot_id, :trade_value ]
    end

    create_table :daily_metrics do |t|
      t.references :snapshot_item, null: false, foreign_key: true
      t.date :metric_date, null: false
      t.bigint :institution_net_purchase
      t.bigint :pension_net_purchase
      t.bigint :foreign_net_purchase
      t.bigint :individual_net_purchase
      t.decimal :execution_strength, precision: 10, scale: 2
      t.jsonb :raw_investor_payload, null: false, default: {}
      t.jsonb :raw_strength_payload, null: false, default: {}
      t.timestamps

      t.index [ :snapshot_item_id, :metric_date ], unique: true
    end

    create_table :leader_selections do |t|
      t.references :market_snapshot, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.timestamps

      t.index [ :market_snapshot_id, :sector_id ], unique: true
      t.index [ :market_snapshot_id, :stock_id ], unique: true
    end

    create_table :collection_logs do |t|
      t.references :market_snapshot, foreign_key: true
      t.string :level, null: false, default: "info"
      t.string :stage, null: false
      t.string :endpoint
      t.string :api_id
      t.integer :response_code
      t.text :message
      t.jsonb :details, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps

      t.index [ :market_snapshot_id, :occurred_at ]
      t.index [ :level, :stage ]
    end
  end
end
