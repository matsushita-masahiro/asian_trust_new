module BonusTestHelper
  # ボーナス計算テスト用のヘルパーメソッド
  
  def self.create_bonus_test_report(month_str = Date.current.strftime("%Y-%m"))
    report = {
      month: month_str,
      generated_at: Time.current,
      users: [],
      summary: {},
      validation: {}
    }
    
    test_users = User.where("email LIKE '%test_bonus%'").includes(:level, :referrer, :purchases)
    
    test_users.each do |user|
      user_data = {
        id: user.id,
        name: user.name,
        level: user.level.name,
        status: user.status,
        referrer: user.referrer&.name,
        own_sales: user.own_monthly_sales_total(month_str),
        descendant_sales: user.all_descendants_monthly_sales_total(month_str),
        total_bonus: user.bonus_in_month(month_str),
        bonus_eligible: user.bonus_eligible?,
        purchases: []
      }
      
      # 購入詳細
      user.purchases.in_month_tokyo(month_str).each do |purchase|
        user_data[:purchases] << {
          product: purchase.product.name,
          quantity: purchase.quantity,
          amount: purchase.unit_price * purchase.quantity,
          date: purchase.purchased_at,
          customer: purchase.customer.name
        }
      end
      
      report[:users] << user_data
    end
    
    # サマリー計算
    report[:summary] = {
      total_users: test_users.count,
      active_users: test_users.where(status: 'active').count,
      suspended_users: test_users.where(status: 'suspended').count,
      inactive_users: test_users.where(status: 'inactive').count,
      total_sales: report[:users].sum { |u| u[:own_sales] + u[:descendant_sales] },
      total_bonus: report[:users].sum { |u| u[:total_bonus] },
      bonus_eligible_users: report[:users].count { |u| u[:bonus_eligible] }
    }
    
    # バリデーション
    report[:validation] = {
      non_eligible_users_with_bonus: report[:users].count { |u| !u[:bonus_eligible] && u[:total_bonus] > 0 },
      suspended_users_with_bonus: report[:users].count { |u| u[:status] == 'suspended' && u[:total_bonus] > 0 },
      inactive_users_with_bonus: report[:users].count { |u| u[:status] == 'inactive' && u[:total_bonus] > 0 }
    }
    
    report
  end
  
  def self.export_bonus_test_csv(month_str = Date.current.strftime("%Y-%m"))
    require 'csv'
    
    report = create_bonus_test_report(month_str)
    
    CSV.generate(headers: true) do |csv|
      csv << [
        'ユーザーID', 'ユーザー名', 'レベル', 'ステータス', '紹介者',
        '自身売上', '下位売上', '総売上', 'ボーナス', 'ボーナス対象',
        '購入件数', '直接紹介数'
      ]
      
      report[:users].each do |user|
        referrals_count = User.where(referred_by_id: user[:id], email: '%test_bonus%').count
        
        csv << [
          user[:id],
          user[:name],
          user[:level],
          user[:status],
          user[:referrer] || 'なし',
          user[:own_sales],
          user[:descendant_sales],
          user[:own_sales] + user[:descendant_sales],
          user[:total_bonus],
          user[:bonus_eligible] ? 'はい' : 'いいえ',
          user[:purchases].count,
          referrals_count
        ]
      end
    end
  end
  
  def self.generate_hierarchy_diagram
    test_users = User.where("email LIKE '%test_bonus%'").includes(:level, :referrer, :referrals)
    root_users = test_users.where(referred_by_id: nil)
    
    diagram = []
    
    root_users.each do |root|
      diagram << build_user_tree(root, 0, test_users)
    end
    
    diagram.join("\n")
  end
  
  private
  
  def self.build_user_tree(user, depth, all_users)
    indent = "  " * depth
    prefix = depth == 0 ? "" : "└─ "
    
    bonus = user.bonus_in_month(Date.current.strftime("%Y-%m"))
    status_icon = case user.status
                  when 'active' then '✅'
                  when 'suspended' then '⚠️'
                  when 'inactive' then '❌'
                  end
    
    line = "#{indent}#{prefix}#{user.name} (#{user.level.name}) #{status_icon} ¥#{number_with_delimiter(bonus)}"
    
    children = all_users.where(referred_by_id: user.id)
    children_lines = children.map { |child| build_user_tree(child, depth + 1, all_users) }
    
    [line, *children_lines].join("\n")
  end
  
  def self.number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end