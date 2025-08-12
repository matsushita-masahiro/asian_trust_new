class AddSellerPriceToPurchaseItems < ActiveRecord::Migration[7.1]
  def change
    add_column :purchase_items, :seller_price, :integer, comment: '販売店の購入単価（購入時点での価格）'
    
    # 既存データに対して販売店購入単価を設定
    reversible do |dir|
      dir.up do
        PurchaseItem.includes(:product, purchase: :user).find_each do |item|
          purchase = item.purchase
          user = purchase.user
          product = item.product
          
          # 販売店のレベルに応じた価格を取得
          seller_price = product.product_prices.find_by(level_id: user.level_id)&.price || 0
          item.update_column(:seller_price, seller_price)
        end
      end
    end
  end
end