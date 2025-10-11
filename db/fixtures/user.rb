require 'csv'

# CSVファイルからユーザーデータを読み込んでfixtureデータを作成
class UserFixture
  def self.create_users
    puts "📊 Loading users from CSV file..."
    
    # 既存のユーザーデータをクリーンアップ
    puts "🧹 Cleaning up existing user data..."
    adapter = ActiveRecord::Base.connection.adapter_name
    
    begin
      if adapter == "SQLite"
        ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
        PurchaseItem.delete_all
        Purchase.delete_all
        User.delete_all
        ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='users'")
        ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='purchases'")
        ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='purchase_items'")
        ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
      else
        PurchaseItem.delete_all
        Purchase.delete_all
        User.delete_all
      end
      puts "✅ Cleanup completed"
    rescue => e
      puts "⚠️  Cleanup warning: #{e.message}"
      puts "Continuing with user creation..."
    end
    
    # CSVファイルのパス
    csv_path = Rails.root.join('db', 'fixtures', 'users.csv')
    
    unless File.exist?(csv_path)
      puts "❌ CSV file not found: #{csv_path}"
      puts "Please upload your CSV file to db/fixtures/users.csv"
      return
    end
    
    # 既存のユーザーを名前でインデックス化（紹介者検索用）
    existing_users = {}
    
    # LステップIDカウンター
    lstep_id_counter = 1
    created_users = {}
    
    # CSVファイルを読み込み（ヘッダー行をスキップ）
    CSV.foreach(csv_path, headers: true, encoding: 'UTF-8') do |row|
      # CSVの列を取得（新しい構造に対応）
      no = row['No']&.to_s&.strip
      level_name = row['level']&.to_s&.strip
      name = row['name']&.to_s&.strip
      email = row['email']&.to_s&.strip
      referred_by_name = row['紹介者']&.to_s&.strip
      
      # 空行や無効なデータをスキップ
      next if name.blank? || email.blank? || level_name.blank?
      next if name.include?('期生') # "二期生", "三期生", "四期生" などの行をスキップ
      
      # レベルを取得
      level = Level.find_by(name: level_name)
      if level.nil?
        puts "⚠️  Level '#{level_name}' not found for user #{name}. Skipping..."
        next
      end
      
      # 紹介者を検索（名前で検索、複数の表記に対応）
      referred_by = nil
      if referred_by_name.present? && referred_by_name != 'なし'
        # 紹介者名のクリーンアップ（様、　などを除去）
        clean_referred_name = referred_by_name.gsub(/様|　|\s+/, '').strip
        
        # アジアビジネストラストの場合は直接検索
        if clean_referred_name == 'アジアビジネストラスト'
          referred_by = created_users['アジアビジネストラスト']
        else
          # 今回作成したユーザーから検索（完全一致を優先）
          referred_by = created_users[clean_referred_name]
          
          # 完全一致しない場合は部分一致で検索
          if referred_by.nil?
            referred_by = created_users.values.find { |u| u.name.include?(clean_referred_name) }
          end
          
          # 特別なケース処理
          case clean_referred_name
          when /恵向咲佑里|村上ひさ子/
            # 恵向咲佑里（村上ひさ子）の場合
            referred_by = created_users.values.find { |u| u.name.include?("恵向咲佑里") }
          when /藤井聖子|鹿田聖子/
            # 藤井聖子（鹿田聖子）の場合
            referred_by = created_users.values.find { |u| u.name.include?("鹿田聖子") || u.name.include?("藤井聖子") }
          when /堀内康代/
            referred_by = created_users.values.find { |u| u.name.include?("堀内康代") }
          when /中山良一/
            referred_by = created_users.values.find { |u| u.name.include?("中山良一") }
          when /西田裕胡/
            referred_by = created_users.values.find { |u| u.name.include?("西田裕胡") }
          when /関口満紀枝/
            referred_by = created_users.values.find { |u| u.name.include?("関口満紀枝") }
          when /大森健巳/
            referred_by = created_users.values.find { |u| u.name.include?("大森健巳") }
          end
        end
        
        if referred_by.nil?
          puts "⚠️  Referred by user '#{referred_by_name}' not found for user #{name}"
        end
      end
      
      # LステップIDを生成
      lstep_user_id = "lstep_csv_#{format('%04d', lstep_id_counter)}"
      lstep_id_counter += 1
      
      # ユーザーを作成
      begin
        user = User.create!(
          name: name,
          email: email,
          password: "password", # デフォルトパスワード
          level_id: level.id,
          referred_by_id: referred_by&.id,
          lstep_user_id: lstep_user_id,
          confirmed_at: Time.current
        )
        
        # 作成したユーザーを記録
        created_users[name] = user
        
        referred_info = referred_by ? " (紹介者: #{referred_by.name})" : ""
        puts "✅ Created user: #{user.name} (#{user.email}) - Level: #{level.name}#{referred_info}"
        
      rescue ActiveRecord::RecordInvalid => e
        puts "❌ Failed to create user #{name}: #{e.message}"
      end
    end
    
    puts "📊 CSV user import completed! Created #{created_users.size} users"
  end
end

# fixtureデータを作成
UserFixture.create_users