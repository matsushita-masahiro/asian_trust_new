namespace :bonus do
  desc "ボーナス計算の詳細検証"
  task verify: :environment do
    puts "🔍 ボーナス計算の詳細検証を開始します..."
    
    # テスト対象月
    current_month = Date.current.strftime("%Y-%m")
    puts "対象月: #{current_month}"
    
    # テストユーザーを取得
    test_users = User.where("email LIKE '%test_bonus%'").includes(:level, :referrer, :referrals)
    
    if test_users.empty?
      puts "❌ テストデータが見つかりません。先に db/seeds_bonus_test.rb を実行してください。"
      exit
    end
    
    puts "\n" + "="*80
    puts "📊 詳細ボーナス計算レポート"
    puts "="*80
    
    # 階層ごとに分析
    levels = ["総代理店", "代理店", "アドバイザー"]
    
    levels.each do |level_name|
      users_at_level = test_users.joins(:level).where(levels: { name: level_name })
      next if users_at_level.empty?
      
      puts "\n🏆 #{level_name}レベルの分析"
      puts "-" * 50
      
      users_at_level.each do |user|
        puts "\n👤 #{user.name} (ID: #{user.id})"
        puts "   ステータス: #{user.status}"
        puts "   紹介者: #{user.referrer&.name || 'なし'}"
        
        # 自身の購入
        own_purchases = user.purchases.in_month_tokyo(current_month)
        own_sales = own_purchases.sum { |p| p.unit_price * p.quantity }
        puts "   自身の売上: ¥#{number_with_delimiter(own_sales)} (#{own_purchases.count}件)"
        
        # 下位の購入
        descendant_purchases = user.descendant_purchases.in_month_tokyo(current_month)
        descendant_sales = descendant_purchases.sum { |p| p.unit_price * p.quantity }
        puts "   下位の売上: ¥#{number_with_delimiter(descendant_sales)} (#{descendant_purchases.count}件)"
        
        # ボーナス詳細計算
        total_bonus = user.bonus_in_month(current_month)
        puts "   🎁 総ボーナス: ¥#{number_with_delimiter(total_bonus)}"
        
        # ボーナス内訳を詳細分析
        if user.bonus_eligible?
          puts "   📋 ボーナス内訳:"
          
          # 1. 自身の販売ボーナス
          self_bonus = 0
          own_purchases.each do |purchase|
            bonus = user.bonus_for_purchase(purchase)
            self_bonus += bonus
            if bonus > 0
              puts "     - 自身販売: #{purchase.product.name} x#{purchase.quantity} → ¥#{number_with_delimiter(bonus)}"
            end
          end
          
          # 2. 下位からのボーナス
          descendant_bonus = 0
          descendant_purchases.each do |purchase|
            bonus = user.bonus_for_purchase(purchase)
            descendant_bonus += bonus
            if bonus > 0
              puts "     - #{purchase.user.name}販売: #{purchase.product.name} x#{purchase.quantity} → ¥#{number_with_delimiter(bonus)}"
            end
          end
          
          puts "     📊 自身販売ボーナス: ¥#{number_with_delimiter(self_bonus)}"
          puts "     📊 下位販売ボーナス: ¥#{number_with_delimiter(descendant_bonus)}"
        else
          puts "   ❌ ボーナス対象外（無資格者）"
        end
        
        # 直接紹介者の情報
        direct_referrals = user.referrals.where("email LIKE '%test_bonus%'")
        if direct_referrals.any?
          puts "   👥 直接紹介者 (#{direct_referrals.count}名):"
          direct_referrals.each do |referral|
            referral_sales = referral.purchases.in_month_tokyo(current_month).sum { |p| p.unit_price * p.quantity }
            puts "     - #{referral.name} (#{referral.level.name}): ¥#{number_with_delimiter(referral_sales)}"
          end
        end
      end
    end
    
    # 特殊ケースの分析
    puts "\n" + "="*80
    puts "🚨 特殊ケースの分析"
    puts "="*80
    
    # 停止処分・退会ユーザー
    special_users = test_users.where(status: ['suspended', 'inactive'])
    special_users.each do |user|
      puts "\n⚠️  #{user.name} (#{user.status})"
      purchases = user.purchases.in_month_tokyo(current_month)
      sales = purchases.sum { |p| p.unit_price * p.quantity }
      bonus = user.bonus_in_month(current_month)
      
      puts "   売上: ¥#{number_with_delimiter(sales)} (#{purchases.count}件)"
      puts "   ボーナス: ¥#{number_with_delimiter(bonus)} (#{bonus > 0 ? '⚠️ 異常' : '✅ 正常'})"
      
      # この人の売上が上位にどう影響するかチェック
      if user.referrer && purchases.any?
        referrer_bonus_from_this_user = 0
        purchases.each do |purchase|
          referrer_bonus_from_this_user += user.referrer.bonus_for_purchase(purchase)
        end
        puts "   上位への影響: #{user.referrer.name}に¥#{number_with_delimiter(referrer_bonus_from_this_user)}のボーナス"
      end
    end
    
    # 全体サマリー
    puts "\n" + "="*80
    puts "📈 全体サマリー"
    puts "="*80
    
    total_sales = Purchase.joins(:user).where(users: { email: test_users.pluck(:email) })
                         .in_month_tokyo(current_month)
                         .sum { |p| p.unit_price * p.quantity }
    
    total_bonus = test_users.sum { |u| u.bonus_in_month(current_month) }
    
    puts "総売上: ¥#{number_with_delimiter(total_sales)}"
    puts "総ボーナス: ¥#{number_with_delimiter(total_bonus)}"
    puts "ボーナス率: #{total_sales > 0 ? sprintf('%.2f', (total_bonus.to_f / total_sales * 100)) : 0}%"
    
    # 検証項目チェック
    puts "\n✅ 検証項目チェック:"
    puts "  - 停止処分ユーザーのボーナス: #{special_users.where(status: 'suspended').sum { |u| u.bonus_in_month(current_month) } == 0 ? '✅' : '❌'}"
    puts "  - 退会ユーザーのボーナス: #{special_users.where(status: 'inactive').sum { |u| u.bonus_in_month(current_month) } == 0 ? '✅' : '❌'}"
    puts "  - 階層構造の整合性: #{check_hierarchy_consistency(test_users) ? '✅' : '❌'}"
    puts "  - ボーナス計算の一貫性: #{check_bonus_consistency(test_users, current_month) ? '✅' : '❌'}"
    
    puts "\n🎉 ボーナス計算検証完了！"
  end
  
  private
  
  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
  
  def check_hierarchy_consistency(users)
    users.all? do |user|
      # 紹介者が存在する場合、そのレベルが自分以上であることを確認
      user.referrer.nil? || user.referrer.level.value <= user.level.value
    end
  end
  
  def check_bonus_consistency(users, month)
    users.all? do |user|
      # ボーナス対象者のみがボーナスを受け取っていることを確認
      bonus = user.bonus_in_month(month)
      if user.bonus_eligible? && user.active?
        true # ボーナス対象者は任意の金額OK
      else
        bonus == 0 # 非対象者は0であるべき
      end
    end
  end
end

namespace :bonus do
  desc "ボーナス計算のパフォーマンステスト"
  task performance: :environment do
    puts "⚡ ボーナス計算のパフォーマンステストを開始します..."
    
    test_users = User.where("email LIKE '%test_bonus%'").limit(10)
    current_month = Date.current.strftime("%Y-%m")
    
    require 'benchmark'
    
    puts "\n📊 パフォーマンス測定結果:"
    
    Benchmark.bm(30) do |x|
      x.report("単一ユーザーボーナス計算:") do
        100.times { test_users.first.bonus_in_month(current_month) }
      end
      
      x.report("全ユーザーボーナス計算:") do
        10.times { test_users.map { |u| u.bonus_in_month(current_month) } }
      end
      
      x.report("階層構造取得:") do
        100.times { test_users.first.descendants }
      end
      
      x.report("購入履歴取得:") do
        100.times { test_users.first.purchases.in_month_tokyo(current_month) }
      end
    end
    
    puts "\n🎯 最適化の提案:"
    puts "  - N+1クエリの確認"
    puts "  - インデックスの最適化"
    puts "  - キャッシュの活用"
    puts "  - バッチ処理の検討"
  end
end