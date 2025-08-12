class RestructurePurchasesForMultipleProducts < ActiveRecord::Migration[7.1]
  def up
    # 新しいpurchase_itemsテーブルを作成
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price, null: false
      t.timestamps
    end

    # 既存のpurchasesデータをpurchase_itemsに移行
    Purchase.find_each do |purchase|
      if purchase.product_id.present?
        # 販売店の購入単価を計算
        user = purchase.user
        product = Product.find(purchase.product_id)
        seller_price = product.product_prices.find_by(level_id: user.level_id)&.price || 0
        
        PurchaseItem.create!(
          purchase: purchase,
          product_id: purchase.product_id,
          quantity: purchase.quantity || 1,
          unit_price: purchase.unit_price || 0,
          seller_price: seller_price
        )
      end
    end

    # purchasesテーブルから不要なカラムを削除
    remove_column :purchases, :product_id
    remove_column :purchases, :quantity
    remove_column :purchases, :unit_price
    remove_column :purchases, :price
  end

  def down
    # ロールバック用（簡略化）
    add_column :purchases, :product_id, :integer
    add_column :purchases, :quantity, :integer
    add_column :purchases, :unit_price, :integer
    add_column :purchases, :price, :integer

    drop_table :purchase_items
  end
end