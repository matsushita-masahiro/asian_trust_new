# db/migrate/20250808_restructure_purchases_for_multiple_products.rb
class RestructurePurchasesForMultipleProducts < ActiveRecord::Migration[7.1]  # 7.1のままでOK
  def up
    # 1) テーブル作成（不足列も最初から用意）
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product,  null: false, foreign_key: true
      t.integer :quantity,     null: false, default: 1
      t.integer :unit_price,   null: false, default: 0
      t.integer :seller_price, null: false, default: 0   # ★必要
      t.integer :buyer_price,  null: false, default: 0   # 使うなら
      t.integer :subtotal,     null: false, default: 0
      t.timestamps
    end
    add_index :purchase_items, [:purchase_id, :product_id]

    # OK: ローカル変数にする
    purchase_item_row  = Class.new(ActiveRecord::Base) { self.table_name = "purchase_items" }
    purchase_row       = Class.new(ActiveRecord::Base) { self.table_name = "purchases" }
    product_price_row  = Class.new(ActiveRecord::Base) { self.table_name = "product_prices" }
    user_row           = Class.new(ActiveRecord::Base) { self.table_name = "users" }

    # 以降の処理もローカル変数名で呼び出す
    purchase_row.find_in_batches(batch_size: 1000) do |batch|
      rows = batch.filter_map do |p|
        product_id  = p.respond_to?(:product_id) ? p.product_id : nil
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

    # 3) 旧カラムの削除は分けるのが無難（ここでやるなら存在チェック付きで）
    remove_column :purchases, :product_id if column_exists?(:purchases, :product_id)
    remove_column :purchases, :quantity   if column_exists?(:purchases, :quantity)
    remove_column :purchases, :unit_price if column_exists?(:purchases, :unit_price)
    remove_column :purchases, :price      if column_exists?(:purchases, :price)
  end

  def down
    add_column :purchases, :product_id, :integer unless column_exists?(:purchases, :product_id)
    add_column :purchases, :quantity,   :integer unless column_exists?(:purchases, :quantity)
    add_column :purchases, :unit_price, :integer unless column_exists?(:purchases, :unit_price)
    add_column :purchases, :price,      :integer unless column_exists?(:purchases, :price)
    drop_table :purchase_items if table_exists?(:purchase_items)
  end
end
