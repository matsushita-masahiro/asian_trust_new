namespace :address do
  desc "invoice_baseからAddressモデルへのデータ移行"
  task migrate_from_invoice_base: :environment do
    puts "invoice_baseからAddressへのデータ移行を開始します..."
    
    migrated_count = 0
    skipped_count = 0
    error_count = 0
    
    InvoiceBase.includes(:user).find_each do |invoice_base|
      begin
        # 住所情報が存在する場合のみ移行
        if invoice_base.address.present?
          # 既存の登録住所があるかチェック
          existing_address = Address.find_by(
            user_id: invoice_base.user_id,
            address_type: 'registration'
          )
          
          if existing_address
            puts "ユーザーID #{invoice_base.user_id}: 既に登録住所が存在するためスキップ"
            skipped_count += 1
          else
            # 新しい住所レコードを作成
            address = Address.new(
              user_id: invoice_base.user_id,
              address_type: 'registration',
              postal_code: invoice_base.postal_code,
              address: invoice_base.address
            )
            
            if address.save
              puts "ユーザーID #{invoice_base.user_id}: 住所を移行しました"
              migrated_count += 1
            else
              puts "ユーザーID #{invoice_base.user_id}: 移行エラー - #{address.errors.full_messages.join(', ')}"
              error_count += 1
            end
          end
        else
          puts "ユーザーID #{invoice_base.user_id}: 住所情報が空のためスキップ"
          skipped_count += 1
        end
      rescue => e
        puts "ユーザーID #{invoice_base.user_id}: 例外エラー - #{e.message}"
        error_count += 1
      end
    end
    
    puts "\n移行完了:"
    puts "- 移行成功: #{migrated_count}件"
    puts "- スキップ: #{skipped_count}件"
    puts "- エラー: #{error_count}件"
    puts "- 合計処理: #{migrated_count + skipped_count + error_count}件"
  end
  
  desc "データ整合性チェック"
  task integrity_check: :environment do
    puts "データ整合性チェックを開始します..."
    
    # invoice_baseに住所があるユーザーの数
    invoice_base_with_address = InvoiceBase.where.not(address: [nil, '']).count
    
    # 登録住所を持つユーザーの数
    users_with_registration_address = Address.where(address_type: 'registration').count
    
    puts "invoice_baseに住所があるレコード数: #{invoice_base_with_address}"
    puts "登録住所を持つユーザー数: #{users_with_registration_address}"
    
    # 不整合があるユーザーをチェック
    inconsistent_users = []
    
    InvoiceBase.includes(:user).where.not(address: [nil, '']).find_each do |invoice_base|
      registration_address = Address.find_by(
        user_id: invoice_base.user_id,
        address_type: 'registration'
      )
      
      if registration_address.nil?
        inconsistent_users << invoice_base.user_id
      elsif registration_address.address != invoice_base.address
        puts "ユーザーID #{invoice_base.user_id}: 住所が一致しません"
        puts "  invoice_base: #{invoice_base.address}"
        puts "  address: #{registration_address.address}"
      end
    end
    
    if inconsistent_users.any?
      puts "\n住所が移行されていないユーザー: #{inconsistent_users.join(', ')}"
    else
      puts "\nデータ整合性チェック完了: 問題ありません"
    end
  end
  
  desc "移行のロールバック（テスト用）"
  task rollback_migration: :environment do
    puts "移行のロールバックを開始します..."
    
    deleted_count = Address.where(address_type: 'registration').delete_all
    
    puts "削除された登録住所の数: #{deleted_count}"
    puts "ロールバック完了"
  end
end