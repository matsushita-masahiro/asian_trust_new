class AddDeliveryInformationToExistingPurchases < ActiveRecord::Migration[8.0]
  def up
    # 既存の購入データに配送情報を追加
    Purchase.find_each do |purchase|
      # 既に配送情報が存在する場合はスキップ
      next if purchase.delivery_informations.exists?
      
      # 骨髄幹細胞商品が含まれているかチェック
      has_stem_cell = purchase.purchase_items.joins(:product)
                             .where(products: { name: ['骨髄幹細胞培培養上清液'] })
                             .exists?
      
      if has_stem_cell
        # 骨髄幹細胞商品がある場合：クリニック配送として設定
        # デフォルトでID=2のクリニック（銀座中央クリニック）を設定
        clinic = User.joins(:level).where(levels: { name: 'クリニック' }).first
        
        DeliveryInformation.create!(
          purchase: purchase,
          delivery_type: 'clinic',
          clinic_id: clinic&.id,
          address_type: 'registration',
          delivery_address: clinic ? "#{clinic.invoice_base&.postal_code}|#{clinic.invoice_base&.address}|#{clinic.name}" : "クリニック住所未設定",
          delivery_notes: "既存データからの自動設定"
        )
      else
        # その他の商品：自宅配送として設定
        user = purchase.user
        address = user.registration_address || user.addresses.first
        
        DeliveryInformation.create!(
          purchase: purchase,
          delivery_type: 'home',
          clinic_id: nil,
          address_type: 'registration',
          delivery_address: address ? "#{address.postal_code}|#{address.address}" : "住所未設定",
          delivery_notes: "既存データからの自動設定"
        )
      end
    end
  end

  def down
    # 自動設定された配送情報を削除
    DeliveryInformation.where(delivery_notes: "既存データからの自動設定").destroy_all
  end
end