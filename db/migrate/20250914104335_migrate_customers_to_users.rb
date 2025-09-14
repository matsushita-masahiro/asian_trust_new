class MigrateCustomersToUsers < ActiveRecord::Migration[8.0]
  def up
    # データ移行処理
    Purchase.includes(:customer).find_each do |purchase|
      customer = purchase.customer
      next unless customer
      
      if customer.user_id.present?
        # 既存のユーザーIDを使用
        purchase.update!(buyer_id: customer.user_id)
        puts "Purchase #{purchase.id}: 既存ユーザー #{customer.user_id} を buyer_id に設定"
      else
        # 新しいユーザーを作成
        # お客様レベル（value: 6）を取得
        customer_level = Level.find_by(value: 6)
        
        # メールアドレスが重複しないようにチェック
        email = customer.email.present? ? customer.email : "customer_#{customer.id}@temp.example.com"
        if User.exists?(email: email)
          email = "customer_#{customer.id}_#{Time.current.to_i}@temp.example.com"
        end
        
        user = User.create!(
          name: customer.name || "顧客#{customer.id}",
          email: email,
          password: SecureRandom.hex(16),
          level_id: customer_level&.id,
          phone: customer.phone
        )
        
        purchase.update!(buyer_id: user.id)
        puts "Purchase #{purchase.id}: 新規ユーザー #{user.id} (#{user.name}) を作成し buyer_id に設定"
      end
    end
    
    # データ整合性チェック
    purchases_without_buyer = Purchase.where(buyer_id: nil)
    if purchases_without_buyer.exists?
      puts "警告: buyer_id が設定されていない購入が #{purchases_without_buyer.count} 件あります"
      purchases_without_buyer.each do |p|
        puts "  Purchase ID: #{p.id}, Customer ID: #{p.customer_id}"
      end
    else
      puts "✓ 全ての購入に buyer_id が設定されました"
    end
  end
  
  def down
    # ロールバック処理
    puts "データ移行をロールバックします..."
    Purchase.update_all(buyer_id: nil)
    puts "✓ 全ての buyer_id をクリアしました"
  end
end
