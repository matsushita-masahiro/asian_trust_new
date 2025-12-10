namespace :data do
  desc "Backup current test data"
  task backup_test_data: :environment do
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_dir = Rails.root.join('db', 'backups')
    FileUtils.mkdir_p(backup_dir)
    
    # seeds.rbのバックアップ
    FileUtils.cp(
      Rails.root.join('db', 'seeds.rb'),
      backup_dir.join("seeds_test_#{timestamp}.rb")
    )
    
    puts "✅ Test data backed up to db/backups/seeds_test_#{timestamp}.rb"
  end

  desc "Load production data from CSV files"
  task load_production_data: :environment do
    puts "🔄 Loading production data from CSV files..."
    
    # CSVファイルの存在確認
    csv_files = %w[users.csv]
    csv_dir = Rails.root.join('db', 'csv')
    
    missing_files = csv_files.reject { |file| File.exist?(csv_dir.join(file)) }
    if missing_files.any?
      puts "❌ Missing CSV files: #{missing_files.join(', ')}"
      puts "Please place CSV files in db/csv/ directory"
      exit 1
    end
    
    # 必要なレベルが存在するか確認
    required_levels = %w[総代理店 代理店 アドバイザー サポーター サロン クリニック]
    missing_levels = required_levels.reject { |level_name| Level.find_by(name: level_name) }
    if missing_levels.any?
      puts "❌ Missing levels: #{missing_levels.join(', ')}"
      puts "Please run 'rails db:seed' first to create levels"
      exit 1
    end
    
    # データベースをクリア（開発環境のみ）
    if Rails.env.development?
      puts "🗑️  Clearing existing data..."
      User.destroy_all
      Purchase.destroy_all
      # 他のモデルも必要に応じて
    end
    
    # CSVからデータを読み込み
    load_users_from_csv
    # load_purchases_from_csv
    # load_products_from_csv
    
    puts "✅ Production data loaded successfully!"
  end

  desc "Switch to test data"
  task switch_to_test_data: :environment do
    puts "🔄 Switching to test data..."
    
    # 最新のテストデータバックアップを探す
    backup_dir = Rails.root.join('db', 'backups')
    test_backups = Dir.glob(backup_dir.join('seeds_test_*.rb')).sort.last
    
    if test_backups
      FileUtils.cp(test_backups, Rails.root.join('db', 'seeds.rb'))
      puts "✅ Switched to test data from #{File.basename(test_backups)}"
    else
      puts "❌ No test data backup found"
    end
  end

  private

  def load_users_from_csv
    puts "👥 Loading users..."
    
    # 2パスで処理：まずユーザーを作成、次に紹介者関係を設定
    users_data = []
    
    # 1パス目：ユーザーデータを収集
    CSV.foreach(Rails.root.join('db', 'csv', 'users.csv'), headers: true) do |row|
      users_data << row.to_h
    end
    
    # 2パス目：ユーザーを作成（紹介者なし）
    users_data.each do |row|
      user = User.find_or_initialize_by(email: row['email'])
      
      # レベル名からlevel_idを取得
      level = Level.find_by(name: row['level'])
      unless level
        puts "  ❌ Level '#{row['level']}' not found for #{row['name']}"
        next
      end
      
      # 必須フィールドを設定
      user.assign_attributes(
        name: row['name'],
        phone: row['phone'] || '000-0000-0000', # phoneが必須なのでデフォルト値
        level_id: level.id,
        password: 'temporary_password_123', # Deviseのバリデーション対応
        password_confirmation: 'temporary_password_123'
      )
      
      begin
        user.save!(touch: false)
        puts "  ✅ Created user: #{user.name} (#{user.email})"
        
        # created_atを設定
        if row['created_at'].present?
          User.where(id: user.id).update_all(created_at: Time.parse(row['created_at']))
        end
      rescue => e
        puts "  ❌ Failed to create user #{row['name']}: #{e.message}"
        puts "     Validation errors: #{user.errors.full_messages}" if user.errors.any?
      end
    end
    
    # 3パス目：紹介者関係を設定
    puts "🔗 Setting up referrer relationships..."
    users_data.each do |row|
      next unless row['referrer_name'].present?
      
      user = User.find_by(email: row['email'])
      
      # 紹介者を名前で検索（複数いる場合は最初に登録された人）
      referrer = User.where(name: row['referrer_name']).order(:created_at).first
      
      if user && referrer
        user.update!(referred_by_id: referrer.id)
        puts "  ✅ #{user.name} (#{user.email}) <- #{referrer.name} (#{referrer.email})"
      else
        puts "  ❌ Could not find referrer '#{row['referrer_name']}' for #{row['name']} (#{row['email']})"
        
        # 類似した名前を提案
        similar_users = User.where("name LIKE ?", "%#{row['referrer_name']}%")
        if similar_users.any?
          puts "     Similar names found: #{similar_users.pluck(:name, :email)}"
        end
      end
    end
  end

  def load_purchases_from_csv
    puts "🛒 Loading purchases..."
    CSV.foreach(Rails.root.join('db', 'csv', 'purchases.csv'), headers: true) do |row|
      user = User.find_by(email: row['user_email'])
      next unless user
      
      Purchase.find_or_create_by(
        user: user,
        purchased_at: row['purchased_at']
      ) do |purchase|
        purchase.status = row['status']
        purchase.payment_type = row['payment_type']
      end
    end
  end

  def load_products_from_csv
    puts "📦 Loading products..."
    CSV.foreach(Rails.root.join('db', 'csv', 'products.csv'), headers: true) do |row|
      Product.find_or_create_by(name: row['name']) do |product|
        product.base_price = row['base_price']
        product.is_active = row['is_active'] == 'true'
        product.category = row['category']
      end
    end
  end
end