class CreateGlobalAssetSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :global_asset_snapshots do |t|
      t.date :trade_date, null: false
      t.string :snapshot_type, null: false
      t.string :category, null: false
      t.integer :category_position, null: false
      t.string :asset_code, null: false
      t.integer :position, null: false
      t.string :name, null: false
      t.decimal :price, precision: 20, scale: 6, null: false
      t.decimal :change_value, precision: 20, scale: 6, null: false
      t.decimal :change_rate, precision: 12, scale: 6, null: false
      t.string :source, null: false
      t.string :source_symbol, null: false
      t.datetime :captured_at, null: false
      t.jsonb :raw_payload, default: {}, null: false

      t.timestamps

      t.index [ :trade_date, :snapshot_type, :asset_code ], unique: true
      t.index [ :trade_date, :snapshot_type, :category_position, :position ]
    end
  end
end
