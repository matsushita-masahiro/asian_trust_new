# db/migrate/20250808_restructure_purchases_for_multiple_products.rb
class RestructurePurchasesForMultipleProducts < ActiveRecord::Migration[7.1]
  def up
    # --- 1) purchase_items を用意（存在しても壊さない） ---
    unless table_exists?(:purchase_items)
      create_table :purchase_items do |t|
        t.references :purchase, null: false, foreign_key: true
        t.references :product,  null: false, foreign_key: true
        t.integer :quantity,     null: false, default: 1
        t.integer :unit_price,   null: false, default: 0
        t.integer :seller_price, null: false, default: 0
        t.integer :buyer_price,  null: false, default: 0
        t.integer :subtotal,     null: false, default: 0
        t.timestamps
      end
    end

    # 既存環境向けの保険（足りない列/索引だけ追加）
    add_column :purchase_items, :quantity,     :integer, null: false, default: 1 unless column_exists?(:purchase_items, :quantity)
    add_column :purchase_items, :unit_price,   :integer, null: false, default: 0 unless column_exists?(:purchase_items, :unit_price)
    add_column :purchase_items, :seller_price, :integer, null: false, default: 0 unless column_exists?(:purchase_items, :seller_price)
    add_column :purchase_items, :buyer_price,  :integer, null: false, default: 0 unless column_exists?(:purchase_items, :buyer_price)
    add_column :purchase_items, :subtotal,     :integer, null: false, default: 0 unless column_exists?(:purchase_items, :subtotal)
    add_index  :purchase_items, [:purchase_id, :product_id] unless index_exists?(:purchase_items, [:purchase_id, :product_id])

    # --- 2) バックフィル（匿名モデル = ローカル変数で）---
    purchase_item_row  = Class.new(ActiveRecord::Base) { self.table_name = "purchase_items" }
    purchase_row       = Class.new(ActiveRecord::Base) { self.table_name = "purchases" }
    product_price_row  = Class.new(ActiveRecord::Base) { self.table_name = "product_prices" }
    user_row           = Class.new(ActiveRecord::Base) { self.table_name = "users" }

    # 旧カラムがまだあり、かつ未移行（purchase_itemsが空）のときだけ実行
    if column_exists?(:purchases, :product_id) && purchase_item_row.count.zero?
      purchase_row.find_in_batches(batch_size: 1000) do |batch|
        rows = batch.filter_map do |p|
          product_id = p.respond_to?(:product_id) ? p.product_id : nil
          next unless product_id.present?

          level_id    = user_row.where(id: p.user_id).pick(:level_id)
          quantity    = (p.try(:quantity) || 1).to_i
          unit_price  = (p.try(:unit_price) || p.try(:price) || 0).to_i
          buyer_price = unit_price
          seller_prc  = product_price_row.where(product_id: product_id, level_id: level_id).pick(:price) || 0
          subtotal    = quantity * unit_price

          {
            purchase_id:  p.id,
            product_id:   product_id,
            quantity:     quantity,
            unit_price:   unit_price,
            buyer_price:  buyer_price,
            seller_price: seller_prc,
            subtotal:     subtotal,
            created_at:   Time.current,
            updated_at:   Time.current
          }
        end
        purchase_item_row.insert_all(rows) if rows.any?
      end
    end

    # --- 3) 旧カラムの削除（存在する場合のみ）---
    remove_column :purchases, :product_id if column_exists?(:purchases, :product_id)
    remove_column :purchases, :quantity   if column_exists?(:purchases, :quantity)
    remove_column :purchases, :unit_price if column_exists?(:purchases, :unit_price)
    remove_column :purchases, :price      if column_exists?(:purchases, :price)
  end

  def down
    # 元に戻す（存在しなければ追加）
    add_column :purchases, :product_id, :integer unless column_exists?(:purchases, :product_id)
    add_column :purchases, :quantity,   :integer unless column_exists?(:purchases, :quantity)
    add_column :purchases, :unit_price, :integer unless column_exists?(:purchases, :unit_price)
    add_column :purchases, :price,      :integer unless column_exists?(:purchases, :price)

    drop_table :purchase_items if table_exists?(:purchase_items)
  end
end
